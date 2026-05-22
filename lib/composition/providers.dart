import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/weather_forecast/get_city_forecast.dart';
import '../domain/weather_forecast/weather_forecast_repository.dart';
import '../infra/network/dio_http_service.dart';
import '../infra/network/http_service.dart';
import '../infra/weather_forecast/cwa_weather_forecast_repository.dart';

/// Composition Root：所有 Riverpod Provider 集中於此檔。
///
/// 上層（Notifier / Widget）只看 Provider，不知道具體實作；切換實作或加入
/// fake / test override 時都只動這一檔。

/// CWA API token，透過 `--dart-define=CWA_API_TOKEN=...` 注入。
///
/// 預設空字串時，CWA 會回 401 → `RemoteServiceError(401)` → UI 顯示
/// 「伺服器錯誤（401）」，提示開發者補上 token。
const String cwaApiToken = String.fromEnvironment(
  'CWA_API_TOKEN',
  defaultValue: '',
);

final cwaApiTokenProvider = Provider<String>((ref) => cwaApiToken);

final httpServiceProvider = Provider<HttpService>((ref) {
  final dio = DioHttpService();
  ref.onDispose(dio.close);
  return dio;
});

final weatherForecastRepositoryProvider =
    Provider<WeatherForecastRepository>((ref) {
  return CwaWeatherForecastRepository(
    httpService: ref.watch(httpServiceProvider),
    apiToken: ref.watch(cwaApiTokenProvider),
  );
});

final getCityForecastProvider = Provider<GetCityForecast>((ref) {
  return GetCityForecast(ref.watch(weatherForecastRepositoryProvider));
});
