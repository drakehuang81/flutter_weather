# flutter_weather — 技術設計文件

> 對應需求：`spec/require.pdf`
> 作業目標：建立 Flutter app，串接 CWA「一般天氣預報-今明 36 小時」API（`/v1/rest/datastore/F-C0032-001`），用戶輸入城市名稱、按下「確認」取得預報；顯示區塊有四種狀態：初始 / Loading / 資料 / 錯誤。
> 架構方法：**DDD 戰術建模 + Clean Architecture 四層**。

---

## 1. 範圍與假設

### In Scope

- 單一頁面：城市搜尋輸入框 + 顯示區塊
- API 串接：CWA F-C0032-001
- 四種顯示狀態（Initial / Loading / Loaded / Error）
- 錯誤處理：輸入無效、城市不存在、回應格式錯誤、網路/伺服器錯誤

### Out of Scope（YAGNI）

- 多語系、深色模式（除非作業評估明確要求）
- 收藏城市、歷史紀錄、地圖、定位
- 七日預報、雷達圖
- 離線快取（記憶體層級短期快取除外）

### 前置假設

| 假設 | 處理方式 |
| --- | --- |
| CWA API 需要 `Authorization` token（PDF 未提供） | 透過 `--dart-define=CWA_API_TOKEN=...` 注入；README 給出申請連結 |
| 城市名稱使用 CWA 官方鍵值（例：`臺北市`、`新北市`）| 輸入做 trim；若 CWA 回傳 `records.location` 為空陣列即視為「找不到城市」 |
| 評估標準偏重「清晰度 / 易用性 / 完成度」 | 介面簡單；錯誤訊息中文化 |

---

## 2. Ubiquitous Language（領域詞彙）

| 中文 | English | 說明 |
| --- | --- | --- |
| 城市名稱 | CityName | 用戶輸入並對齊 CWA `locationName` 的值物件，已 trim 且非空 |
| 天氣預報 | WeatherForecast | 一個城市的「今明 36 小時」預報結果（聚合根） |
| 預報時段 | ForecastPeriod | 預報內的單一時段（典型為 12 小時） |
| 天氣描述 | WeatherDescription | 該時段 `Wx` 的中文敘述（例：晴時多雲） |
| 降雨機率 | PrecipitationProbability | 該時段 `PoP`，整數百分比 |
| 溫度區間 | TemperatureRange | 該時段 `MinT`/`MaxT`，攝氏 |
| 舒適度 | ComfortIndex | 該時段 `CI` 中文敘述 |

UI 與 code 內部一律使用上述同樣的詞彙。

---

## 3. Bounded Context

只有單一上下文 **WeatherForecast**。所有領域物件、用例、Repository 皆隸屬此上下文。CWA 是 *upstream / supplier*，我們是 *downstream / conformist*：以 Anti-Corruption Layer（基礎設施層的 DTO + Mapper）轉換為自家領域模型。

---

## 4. 戰術建模

### 4.1 Value Objects

#### `CityName`

- 不可變、值相等性
- 建構規則：
  - `trim()` 後不可為空
  - 長度 1–20 字
  - 不含換行字元
- 違反規則 → 拋 `InvalidCityNameError`
- 範例：`CityName('臺北市')` ✅、`CityName('   ')` ❌、`CityName('A' * 50)` ❌

#### `TemperatureRange`

- `min`、`max` 皆為 `int`（攝氏）
- 不變式：`min <= max`

#### `PrecipitationProbability`

- 0 ≤ `value` ≤ 100

### 4.2 Entities & Aggregate

#### `ForecastPeriod`（Entity）

```
ForecastPeriod {
  DateTime startTime
  DateTime endTime
  WeatherDescription description   // e.g. "晴時多雲"
  TemperatureRange temperature
  PrecipitationProbability pop
  ComfortIndex comfort
}
```

不變式：`startTime < endTime`

#### `WeatherForecast`（Aggregate Root）

```
WeatherForecast {
  CityName city
  List<ForecastPeriod> periods    // 至少 1 筆，依 startTime 升冪
  DateTime fetchedAt
}
```

不變式：
- `periods` 非空
- 依 `startTime` 升冪排序
- 同一聚合內所有 period 同屬一個 `city`

### 4.3 Domain Errors（密封型別）

```
sealed class DomainFailure
  ├─ InvalidCityNameError(String reason)         // 輸入錯誤
  ├─ CityNotFoundError(CityName city)            // API 回傳沒有此城市
  ├─ MalformedForecastDataError(String detail)   // API 格式不符
  ├─ NetworkUnavailableError                     // 連線失敗
  └─ RemoteServiceError(int? statusCode)         // 4xx/5xx
```

「Failure」是業務語言，不洩漏 `DioException`、`ApiException`、`FormatException` 到 Domain 層之外。

### 4.4 Domain Service / Use Case

#### `GetCityForecast`（Application Use Case）

```
class GetCityForecast {
  GetCityForecast(this._repo);
  final WeatherForecastRepository _repo;

  Future<Result<WeatherForecast, DomainFailure>> call(String rawInput);
}
```

流程：
1. `CityName.parse(rawInput)` → 失敗回 `InvalidCityNameError`
2. `_repo.fetchByCity(city)` → 成功回 `Ok(forecast)`
3. 任一基礎設施層拋的 `DomainFailure` → 包成 `Err`

Use Case 是 Application Layer 的薄殼，**不放 UI 狀態、不放網路細節**。

`Result<T, E>` 採用簡單 sealed class（`Ok` / `Err`），避免 Use Case 以拋例外傳遞商業預期錯誤。

### 4.5 Repository Interface（Domain Layer）

```
abstract class WeatherForecastRepository {
  Future<WeatherForecast> fetchByCity(CityName city);
  // 失敗時拋 DomainFailure（不是 ApiException）
}
```

Domain 只認識 `WeatherForecastRepository` 抽象介面，**永遠不 import 任何 `infra/` 內的具體類別**。

---

## 4.6 命名規範（全專案統一）

> 兩項定案：(1) Domain Failure 子型別一律用 `Error` 後綴；(2) Result 自寫 `sealed class Result<T, E> = Ok | Err`，不引入 `fpdart` / `dartz`。

### A. 檔案與目錄

- 全 `lower_snake_case.dart`（範例：`weather_forecast.dart`）
- 一個 public 類別一個檔案（VO / Entity / Mapper / Notifier 都各自獨立檔）
- 目錄以**概念**命名，不以分類複數命名（用 `domain/weather_forecast/`，不用 `entities/` 或 `models/`）
- 測試檔：`<被測>_test.dart`，目錄結構鏡像 `lib/` 至 `test/`

### B. Domain Layer

| 種類 | 規則 | 範例 |
| --- | --- | --- |
| Entity / Aggregate Root | 名詞，無後綴 | `WeatherForecast`、`ForecastPeriod` |
| Value Object | 名詞，無後綴 | `CityName`、`TemperatureRange`、`PrecipitationProbability` |
| Repository 介面 | `XxxRepository` | `WeatherForecastRepository` |
| Failure 密封基底 | `XxxFailure` | `DomainFailure` |
| Failure 子型別 | 業務名詞 + `Error` | `InvalidCityNameError`、`CityNotFoundError`、`MalformedForecastDataError`、`NetworkUnavailableError`、`RemoteServiceError` |
| Domain Service（少用） | `XxxPolicy` 或動詞名詞 | `ForecastFreshnessPolicy` |

### C. Application Layer（UseCase）

| 種類 | 規則 | 範例 |
| --- | --- | --- |
| Use Case 類別 | 動詞 + 名詞，**不**加 `UseCase` 後綴 | `GetCityForecast` |
| Use Case 方法 | 一律 `call(...)`，呼叫端寫 `await useCase(input)` | `Future<Result<WeatherForecast, DomainFailure>> call(String input)` |
| Result 包裝 | 自寫 sealed `Result<T, E>` + `Ok<T, E>` / `Err<T, E>` | `Ok(forecast)`、`Err(CityNotFoundError(city))` |

### D. Infrastructure Layer

| 種類 | 規則 | 範例 |
| --- | --- | --- |
| Repository 實作 | `<供應方><Domain>Repository` | `CwbWeatherForecastRepository` |
| DTO | `<供應方><概念>Dto` | `CwbForecastDto` |
| Mapper | `<供應方><概念>Mapper`，方法 `toDomain` / `toDto` | `CwbForecastMapper.toDomain(dto)` |
| ApiRequest 子類 | `<動作><概念>Request` | `GetCwbForecastRequest` |
| 共用網路型別 | 已固定 | `ApiRequest`、`ApiException`、`HttpService`、`HttpMethod` |

> 「供應方前綴」（如 `Cwb`）讓未來切換或並存資料來源（例：`OpenWeather...`）時命名不衝突。

### E. Presentation Layer

| 種類 | 規則 | 範例 |
| --- | --- | --- |
| Page（路由頂層） | `XxxPage` | `WeatherSearchPage` |
| 區塊 Widget | 描述功能的名詞 | `LocationInputBar`、`ForecastView`、`InitialView`、`LoadingView`、`ErrorView` |
| State 密封基底 | `XxxViewState` | `WeatherViewState` |
| State 子型別 | 狀態名詞 | `Initial`、`Loading`、`Loaded`、`Failure` |
| Notifier | `XxxNotifier` | `WeatherSearchNotifier` |
| Provider 變數 | `xxxProvider`（lowerCamelCase） | `weatherSearchNotifierProvider`、`httpServiceProvider`、`getCityForecastProvider` |

### F. 橫切 / 共用

| 種類 | 規則 |
| --- | --- |
| Log 工具 | `Log`（已存在） |
| 常數 | 放入相關類別 `static const`；獨立常數類用 `XxxConst` |
| Extension | 統一用 `Extension` 後綴（已存在 `HttpMethodExtension`），不用 `X` 縮寫 |

### G. 命名禁忌

- ❌ `Manager` / `Helper` / `Util`（語意不明，通常代表抽象未到位）
- ❌ `IXxxRepository`（Dart 慣例不用 `I` 前綴）
- ❌ `Service`（除非真的是無狀態的程序集合，例：`HttpService`），其餘優先選更具體的名詞
- ❌ Domain Layer 出現 `Dto` / `Dio` / `Sqlite` 等基礎設施詞彙
- ❌ 用 `Exception` 命名 Domain Failure（保留給 SDK / Dart 原生例外）

---

## 5. Clean Architecture 分層

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation         Flutter Widgets + Riverpod Notifier   │
│  ─────────────────────────────────────────────────────────  │
│  Application          Use Cases（GetCityForecast）           │
│  ─────────────────────────────────────────────────────────  │
│  Domain               Entities / VO / Failure / Repo intf   │
│  ─────────────────────────────────────────────────────────  │
│  Infrastructure       Dio HttpService + CwbRepositoryImpl   │
└─────────────────────────────────────────────────────────────┘
       ▲ 依賴方向：上層只依賴下層的「抽象介面」
       │ Composition Root（main.dart / providers）做 DI 組裝
```

### 依賴規則

1. Domain 層**不**依賴任何其他層或框架（不 import `flutter`、`dio`、`riverpod`）。
2. Application 層只依賴 Domain。
3. Infrastructure 層 implement Domain 介面，依賴 Domain + 第三方 SDK。
4. Presentation 層依賴 Application（Use Case）與 Domain（型別），**不**直接呼叫 Infrastructure。
5. 框架/SDK 例外（`DioException`、`FormatException`）只能在 Infrastructure 層內部存在，越過邊界前必須翻譯成 `DomainFailure`。

### Composition Root

`lib/main.dart` 內 `ProviderScope` 與 `lib/composition/providers.dart` 是**唯一** `Provider` 連線之處。Widget 透過 `ref.watch` 取得 Notifier；Notifier 透過 `ref.read` 取得 Use Case；Use Case 透過建構子注入取得 Repository；Repository 透過建構子注入取得 `HttpService`。

---

## 6. 模組設計

### 6.1 Presentation

#### State

```
sealed class WeatherViewState
  ├─ Initial                             // 尚未搜尋
  ├─ Loading(CityName queryingCity)      // 顯示讀取中
  ├─ Loaded(WeatherForecast forecast)    // 顯示資料
  └─ Failure(String userMessage, DomainFailure raw)
```

四子型別與「顯示區塊的四個 Widget」一對一對應，避免「Loading + 既有資料」這類混合態的歧義。

#### Notifier

```
class WeatherSearchNotifier extends Notifier<WeatherViewState> {
  late final GetCityForecast _useCase;

  @override
  WeatherViewState build() {
    _useCase = ref.read(getCityForecastProvider);
    return const Initial();
  }

  Future<void> search(String rawInput) async {
    final parsed = CityName.tryParse(rawInput);
    if (parsed == null) {
      state = Failure('請輸入有效的城市名稱', InvalidCityNameError(...));
      return;
    }
    state = Loading(parsed);
    final result = await _useCase(rawInput);
    state = switch (result) {
      Ok(value: final forecast) => Loaded(forecast),
      Err(failure: final f) => Failure(_humanize(f), f),
    };
  }

  String _humanize(DomainFailure f) => switch (f) {
    InvalidCityNameError() => '請輸入有效的城市名稱',
    CityNotFoundError(city: final c) => '找不到 ${c.value} 的預報資料',
    MalformedForecastDataError() => '伺服器回傳的資料格式不正確',
    NetworkUnavailableError() => '網路連線失敗，請檢查網路設定',
    RemoteServiceError(statusCode: final s) => '伺服器錯誤（${s ?? '未知'}）',
  };
}
```

關鍵原則：
- `search()` **不回傳值**；UI 不能用回傳值決定流程，只能 `ref.watch` 觀察 state。
- `_humanize` 把 Failure 翻成 UI 字串，是「展示層的決策」，不放在 Domain。

#### Widgets

```
WeatherSearchPage
 ├─ LocationInputBar         (TextField + 「確認」按鈕)
 └─ WeatherResultSection     (switch state)
     ├─ InitialView          (引導文字 + 圖標)
     ├─ LoadingView          (CircularProgressIndicator + 「正在查詢...」)
     ├─ ForecastView         (List of ForecastPeriodCard)
     └─ ErrorView            (錯誤訊息 + 重試按鈕)
```

- `WeatherResultSection` 內用 `switch (state)` pattern match，每個分支回傳對應 Widget；強型別保證新增 state 子型別時編譯器會逼著補上。
- **不用 `showDialog` 表示 Loading**（PDF 明確要求）。

### 6.2 Application

```
lib/application/
└── weather_forecast/
    ├── get_city_forecast.dart       // Use Case
    └── result.dart                  // Ok / Err sealed class
```

### 6.3 Domain

```
lib/domain/
└── weather_forecast/
    ├── city_name.dart               // VO
    ├── forecast_period.dart         // Entity + VO（TemperatureRange、Pop、Comfort）
    ├── weather_forecast.dart        // Aggregate Root
    ├── weather_forecast_repository.dart  // 介面
    └── failure.dart                 // sealed DomainFailure
```

### 6.4 Infrastructure

```
lib/core/infra/network/              // 已存在的通用網路層
└── ...

lib/infra/weather_forecast/
├── cwb_forecast_dto.dart            // 與 CWA JSON 1:1 對應
├── cwb_forecast_mapper.dart         // DTO → Domain；失敗丟 MalformedForecastDataError
├── cwb_forecast_request.dart        // extends ApiRequest<CwbForecastDto>
└── cwb_weather_forecast_repository.dart  // implements WeatherForecastRepository
```

`CwbWeatherForecastRepository` 工作：
1. 組 `CwbForecastRequest(cityName, apiToken)`
2. 呼叫注入的 `HttpService.execute()`
3. 拿到 `CwbForecastDto` → 經 Mapper 轉 `WeatherForecast`
4. **錯誤翻譯**（這是 ACL 核心）：
   - `ApiException.isNetworkError` → `NetworkUnavailableError`
   - `ApiException.isClientError / isServerError` → `RemoteServiceError(statusCode)`
   - `MalformedForecastDataError`（Mapper 拋的）原樣往上
   - `FormatException` / `TypeError` → `MalformedForecastDataError`
   - CWA 回 200 但 `records.location` 為空 → `CityNotFoundError`

---

## 7. 主要資料流（Sequence）

### 7.1 搜尋成功

```
User -> LocationInputBar : 輸入「臺北市」+ 點擊確認
LocationInputBar -> WeatherSearchNotifier : search("臺北市")
WeatherSearchNotifier -> CityName : tryParse("臺北市")  -> CityName ok
WeatherSearchNotifier : state = Loading
WeatherSearchNotifier -> GetCityForecast : call("臺北市")
GetCityForecast -> WeatherForecastRepository : fetchByCity(CityName)
WeatherForecastRepository -> HttpService : execute(CwbForecastRequest)
HttpService -> Dio : GET F-C0032-001?locationName=臺北市
Dio --> HttpService : 200 + JSON
HttpService --> WeatherForecastRepository : CwbForecastDto
WeatherForecastRepository : Mapper.toDomain(dto) -> WeatherForecast
WeatherForecastRepository --> GetCityForecast : WeatherForecast
GetCityForecast --> WeatherSearchNotifier : Ok(forecast)
WeatherSearchNotifier : state = Loaded(forecast)
ForecastView : 重繪
```

### 7.2 搜尋失敗（找不到城市）

```
…（同上至 Dio 200 + JSON）
WeatherForecastRepository : records.location 為空 -> throw CityNotFoundError
GetCityForecast --> WeatherSearchNotifier : Err(CityNotFoundError)
WeatherSearchNotifier : state = Failure("找不到 xxx 的預報資料", ...)
ErrorView : 顯示訊息 + 重試
```

### 7.3 搜尋失敗（API 格式錯誤）

```
…（HttpService 拿到 JSON）
Mapper : 解析過程任何 missing / 型別不符 -> throw MalformedForecastDataError
Repository : 不攔截，直接往上
GetCityForecast --> Notifier : Err(MalformedForecastDataError)
ErrorView : 「伺服器回傳的資料格式不正確」
```

---

## 8. 錯誤處理矩陣

| 觸發情境 | 來源 | 抓在哪一層 | 對應 Failure | UI 訊息 |
| --- | --- | --- | --- | --- |
| 輸入空字串 / 過長 | UI 輸入 | Use Case 入口 | `InvalidCityNameError` | 請輸入有效的城市名稱 |
| 沒有網路 | Dio | Repository ACL | `NetworkUnavailableError` | 網路連線失敗，請檢查網路設定 |
| 4xx (401/403…) | HttpService | Repository ACL | `RemoteServiceError(code)` | 伺服器錯誤（401） |
| 5xx | HttpService | Repository ACL | `RemoteServiceError(code)` | 伺服器錯誤（500） |
| 200 但 JSON 結構不符 | Mapper | Repository | `MalformedForecastDataError` | 伺服器回傳的資料格式不正確 |
| 200 但 records.location 為空 | Repository | Repository | `CityNotFoundError(city)` | 找不到 xx 的預報資料 |
| Use Case 內未預期例外 | 任何 | Notifier 最外層 catch | `MalformedForecastDataError`（保底） | 發生未預期錯誤 |

---

## 9. 設定與機密

- API token：`--dart-define=CWA_API_TOKEN=YOUR_TOKEN`，由 `String.fromEnvironment` 讀取
- 透過 `cwaApiTokenProvider` 注入 Repository，避免散落
- README 紀錄申請流程
- 不在 source code 內 hard-code token

---

## 10. 最終專案結構

```
lib/
├── main.dart                              // Composition Root（runApp + ProviderScope）
├── composition/
│   └── providers.dart                     // 所有 Provider 宣告集中於此
├── domain/
│   └── weather_forecast/
│       ├── city_name.dart
│       ├── forecast_period.dart
│       ├── weather_forecast.dart
│       ├── weather_forecast_repository.dart
│       └── failure.dart
├── application/
│   └── weather_forecast/
│       ├── get_city_forecast.dart
│       └── result.dart
├── infra/
│   └── weather_forecast/
│       ├── cwb_forecast_dto.dart
│       ├── cwb_forecast_mapper.dart
│       ├── cwb_forecast_request.dart
│       └── cwb_weather_forecast_repository.dart
├── core/
│   ├── infra/network/                     // 已實作（ApiRequest / HttpService / ApiException）
│   └── utils/log.dart
└── presentation/
    └── weather_search/
        ├── weather_search_page.dart
        ├── weather_view_state.dart
        ├── weather_search_notifier.dart
        └── widgets/
            ├── location_input_bar.dart
            ├── weather_result_section.dart
            ├── initial_view.dart
            ├── loading_view.dart
            ├── forecast_view.dart
            ├── forecast_period_card.dart
            └── error_view.dart
```

---

## 11. 測試策略

按 TDD 優先順序：

| 層 | 測試類型 | 重點 |
| --- | --- | --- |
| Domain VO（`CityName`） | 純單元 | 不變式：空字串、超長、合法值 |
| Mapper | 純單元 | 完整 JSON / 缺欄位 / 型別錯 / records 空 |
| Use Case | 單元（mock repo） | Ok 路徑、各 DomainFailure 路徑 |
| Notifier | 單元（mock use case + `ProviderContainer`） | state 流轉 Initial → Loading → Loaded/Failure |
| Repository | 整合（mock HttpService） | ACL：把各 ApiException 翻成正確 DomainFailure |
| Widgets | widget test | 四種 state 各自渲染正確子 Widget |
| 全鏈 | 整合（dio 預錄 response） | 端到端 happy path |

不寫的測試：UI 樣式、Dio 內部、Riverpod 本身。

---

## 12. AI 使用揭露（作業要求）

README 內加入章節，內容：
- 使用 **Claude Code (Anthropic)** 作為開發助手
- 用途：協助腳手架、網路層、Use Case 與 Notifier 範本、文件撰寫、code review
- 所有產出由開發者人工 review、修改、測試後才合入

---

## 13. 開放問題（待確認）

1. **CWA token** 是否需要由開發者自己申請？若 reviewer 不方便申請，是否需要附測試用 token 或 mock server？
2. 是否需要在 ForecastView 顯示「資料抓取時間 / 來源」？(`fetchedAt`)
3. 重試按鈕的行為：清空回 Initial、還是直接用上次輸入再打一次？（草案：直接重打）
4. 輸入框是否需要 IME 動作為「搜尋」並支援 Enter 觸發？（建議：是）

---

## 14. 下一步

如本文件審查通過，下一步進入 **writing-plans**：把這份設計拆成可執行的 PR-sized 步驟（建議切：domain → infra → application → presentation → wiring → tests）。
