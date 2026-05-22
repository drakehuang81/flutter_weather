import 'city_name.dart';
import 'failure.dart';
import 'weather_forecast.dart';

/// 天氣預報資料倉儲介面。
///
/// 實作位於基礎設施層，作為與外部資料來源（CWA、其他供應方）的 ACL。
/// 介面只認識領域型別，不暴露任何 SDK / 框架例外。
abstract class WeatherForecastRepository {
  /// 取得指定城市的 36 小時預報。
  ///
  /// 前置條件：[city] 已通過 [CityName] 之 VO 驗證，因此不會拋
  /// [InvalidCityNameError]。
  ///
  /// Throws:
  /// - [CityNotFoundError]        — 上游回應成功但找不到該城市
  /// - [MalformedForecastDataError] — 上游回應格式不符 / 缺欄位 / 數值錯
  /// - [NetworkUnavailableError]  — 連線無法建立（離線、DNS、SSL）
  /// - [RemoteServiceError]       — 上游回應錯誤狀態碼或業務 success=false
  Future<WeatherForecast> fetchByCity(CityName city);
}
