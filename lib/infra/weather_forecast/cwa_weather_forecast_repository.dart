import '../../core/utils/log.dart';
import '../../domain/weather_forecast/city_name.dart';
import '../../domain/weather_forecast/failure.dart';
import '../../domain/weather_forecast/weather_forecast.dart';
import '../../domain/weather_forecast/weather_forecast_repository.dart';
import '../network/api_exception.dart';
import '../network/http_service.dart';
import 'cwa_forecast_dto.dart';
import 'cwa_forecast_mapper.dart';
import 'cwa_forecast_request.dart';

/// CWA F-C0032-001 後端的 [WeatherForecastRepository] 實作。
///
/// ACL：呼叫 [HttpService] 取得 DTO → Mapper 轉領域聚合 → 把
/// [ApiException] / [FormatException] / CWA 200+success=false 等情境
/// 翻譯為 [DomainFailure]。
class CwaWeatherForecastRepository implements WeatherForecastRepository {
  CwaWeatherForecastRepository({
    required HttpService httpService,
    required String apiToken,
    CwaForecastMapper? mapper,
    DateTime Function()? clock,
  })  : _httpService = httpService,
        _apiToken = apiToken,
        _mapper = mapper ?? const CwaForecastMapper(),
        _clock = clock ?? DateTime.now;

  final HttpService _httpService;
  final String _apiToken;
  final CwaForecastMapper _mapper;
  final DateTime Function() _clock;

  @override
  Future<WeatherForecast> fetchByCity(CityName city) async {
    final dto = await _executeRequest(city);
    _ensureSuccess(dto);

    if (dto.locations.isEmpty) {
      throw CityNotFoundError(city.value);
    }
    final location = dto.locations.firstWhere(
      (loc) => loc.locationName == city.value,
      orElse: () => throw CityNotFoundError(city.value),
    );
    return _mapper.toDomain(
      city: city,
      location: location,
      fetchedAt: _clock(),
    );
  }

  Future<CwaForecastResponseDto> _executeRequest(CityName city) async {
    try {
      return await _httpService.execute(
        GetCwaForecastRequest(cityName: city.value, apiToken: _apiToken),
      );
    } on ApiException catch (e) {
      throw _translate(e);
    } on FormatException catch (e, stackTrace) {
      Log.w('CwaWeatherForecastRepository: FormatException - ${e.message}');
      Log.w('stack: $stackTrace');
      throw MalformedForecastDataError(e.message);
    }
  }

  /// 防禦性檢查：若 CWA 回 200 + `success != "true"`（rate limit / 參數錯誤
  /// 等情境），翻譯為 [RemoteServiceError]；token 錯誤實測走 HTTP 401。
  void _ensureSuccess(CwaForecastResponseDto dto) {
    if (dto.success != 'true') {
      Log.w('CwaWeatherForecastRepository: CWA 回應 success=${dto.success}');
      throw const RemoteServiceError(statusCode: 200);
    }
  }

  DomainFailure _translate(ApiException e) {
    if (e.isNetworkError) {
      return const NetworkUnavailableError();
    }
    return RemoteServiceError(statusCode: e.statusCode);
  }
}
