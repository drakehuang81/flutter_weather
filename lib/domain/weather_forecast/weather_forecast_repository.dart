import 'city_name.dart';
import 'failure.dart';
import 'weather_forecast.dart';

/// 天氣預報資料倉儲介面。
///
/// 實作位於基礎設施層，作為與外部資料來源（CWA、其他供應方）的 ACL。
/// 介面只認識領域型別，不暴露任何 SDK / 框架例外。
abstract class WeatherForecastRepository {
  /// 取得 36 小時預報。
  ///
  /// - [city] 給定 → 查單一城市；命中回 1-element list、未命中拋
  ///   [CityNotFoundError]
  /// - [city] 省略 → 「瀏覽模式」，回所有可用城市（CWA 為全 22 縣市；
  ///   上游回空亦不視為錯誤）
  ///
  /// 前置條件：[city] 若給定，必已通過 [CityName] VO 驗證，因此不會拋
  /// [InvalidCityNameError]。
  ///
  /// Throws:
  /// - [CityNotFoundError]          — 指定 city 但上游回空
  /// - [MalformedForecastDataError] — 上游格式不符
  /// - [NetworkUnavailableError]    — 連線失敗
  /// - [RemoteServiceError]         — 上游錯誤狀態碼或業務 success=false
  Future<List<WeatherForecast>> fetchForecasts({CityName? city});
}
