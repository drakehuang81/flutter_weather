import '../../domain/weather_forecast/city_name.dart';
import '../../domain/weather_forecast/failure.dart';
import '../../domain/weather_forecast/weather_forecast.dart';
import '../../domain/weather_forecast/weather_forecast_repository.dart';
import '../result.dart';

/// Use Case：依使用者輸入字串向後端查詢該城市的 36 小時預報。
///
/// 每次呼叫都會打一次 API（無 cache）：
///   1. 將 raw input 轉成 [CityName]（不合法 → `Err(InvalidCityNameError)`）
///   2. 呼叫 [WeatherForecastRepository.fetchByCity]
///   3. 任何 [DomainFailure] 包成 `Err`；成功包成 `Ok`
///
/// 不負責 UI 訊息產生（那是 Presentation 層 `_humanize` 的職責），
/// 不負責例外型別轉換（Repository 已完成 ACL）。
class GetCityForecast {
  GetCityForecast(this._repository);

  final WeatherForecastRepository _repository;

  Future<Result<WeatherForecast, DomainFailure>> call(String rawInput) async {
    final CityName city;
    try {
      city = CityName(rawInput);
    } on InvalidCityNameError catch (failure) {
      return Err(failure);
    }

    try {
      final forecast = await _repository.fetchByCity(city);
      return Ok(forecast);
    } on DomainFailure catch (failure) {
      return Err(failure);
    }
  }
}
