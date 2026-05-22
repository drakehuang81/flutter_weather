import '../network/api_request.dart';
import '../network/http_method.dart';
import 'cwa_forecast_dto.dart';

/// CWA「一般天氣預報-今明 36 小時天氣預報」(F-C0032-001) 取得請求。
///
/// `parseResponse` 直接回傳已 decode 的 [CwaForecastResponseDto]，
/// 由 [HttpService.execute] 的 generic 型別保證呼叫端拿到的是強型別 DTO；
/// 進一步的領域轉換（DTO → WeatherForecast）由 Mapper 負責。
class GetCwaForecastRequest extends ApiRequest<CwaForecastResponseDto> {
  GetCwaForecastRequest({
    required this.cityName,
    required this.apiToken,
  });

  final String cityName;
  final String apiToken;

  @override
  String get baseUrl => 'https://opendata.cwa.gov.tw';

  @override
  String get path => '/api/v1/rest/datastore/F-C0032-001';

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  Map<String, dynamic>? get queryParameters => {
        'Authorization': apiToken,
        'locationName': cityName,
        'format': 'JSON',
      };

  /// 解析回應為 DTO。
  ///
  /// 拋出 [FormatException]（型別不符 / 缺欄位）；由 Repository 翻譯為
  /// 領域層的 [MalformedForecastDataError]。
  @override
  CwaForecastResponseDto parseResponse(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw FormatException('CWA 回應不是 JSON 物件: ${response.runtimeType}');
    }
    return CwaForecastResponseDto.fromJson(response);
  }
}
