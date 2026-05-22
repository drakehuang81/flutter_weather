import '../../domain/weather_forecast/city_name.dart';
import '../../domain/weather_forecast/failure.dart';
import '../../domain/weather_forecast/weather_forecast.dart';
import '../../domain/weather_forecast/weather_forecast_repository.dart';
import '../result.dart';

/// Use Case：依使用者輸入字串向後端查詢預報。
///
/// 兩種模式：
///   - **指定城市**：輸入非空 → 經 [CityName] VO 驗證後呼叫 Repository，
///     回傳 1-element list（或 `Err(CityNotFoundError)`）
///   - **瀏覽全部**：輸入為空（含全空白）→ 直接呼叫 Repository.fetchForecasts()，
///     回傳全 22 縣市
///
/// 不負責 UI 訊息產生；不負責例外型別轉換（Repository 已完成 ACL）。
class GetCityForecast {
  GetCityForecast(this._repository);

  final WeatherForecastRepository _repository;

  Future<Result<List<WeatherForecast>, DomainFailure>> call(
    String rawInput,
  ) async {
    final trimmed = rawInput.trim();

    if (trimmed.isEmpty) {
      return _safeFetch(city: null);
    }

    final CityName city;
    try {
      city = CityName(rawInput);
    } on InvalidCityNameError catch (failure) {
      return Err(failure);
    }
    return _safeFetch(city: city);
  }

  Future<Result<List<WeatherForecast>, DomainFailure>> _safeFetch({
    required CityName? city,
  }) async {
    try {
      final forecasts = await _repository.fetchForecasts(city: city);
      return Ok(forecasts);
    } on DomainFailure catch (failure) {
      return Err(failure);
    }
  }
}
