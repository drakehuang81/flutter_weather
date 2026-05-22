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
/// 此類別是 WeatherForecast 上下文與 CWA 上游之間的 ACL：
/// 1. 組請求並呼叫底層 [HttpService]
/// 2. 解析回應為 DTO
/// 3. 透過 [CwaForecastMapper] 轉成領域聚合
/// 4. 將 [ApiException] 與其他基礎設施例外翻譯為 [DomainFailure]
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
    final location = _findLocation(dto, city);
    return _mapper.toDomain(
      city: city,
      location: location,
      fetchedAt: _clock(),
    );
  }

  /// 同時將底層拋出的 [ApiException]（網路 / HTTP 錯誤）與
  /// [FormatException]（parseResponse / DTO 解析錯）翻譯為 [DomainFailure]。
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
  /// 等情境），翻譯為 [RemoteServiceError] 而非 [CityNotFoundError]，避免
  /// UI 顯示誤導訊息。實測 token 錯時走 HTTP 401，不會進到此路徑。
  void _ensureSuccess(CwaForecastResponseDto dto) {
    if (dto.success != 'true') {
      Log.w('CwaWeatherForecastRepository: CWA 回應 success=${dto.success}');
      throw const RemoteServiceError(statusCode: 200);
    }
  }

  CwaLocationDto _findLocation(
    CwaForecastResponseDto dto,
    CityName city,
  ) {
    if (dto.locations.isEmpty) {
      throw CityNotFoundError(city.value);
    }
    for (final loc in dto.locations) {
      if (loc.locationName == city.value) {
        return loc;
      }
    }
    throw CityNotFoundError(city.value);
  }

  DomainFailure _translate(ApiException e) {
    if (e.isNetworkError) {
      return const NetworkUnavailableError();
    }
    return RemoteServiceError(statusCode: e.statusCode);
  }
}
