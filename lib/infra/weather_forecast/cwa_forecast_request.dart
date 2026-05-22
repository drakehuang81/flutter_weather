import '../network/api_request.dart';
import '../network/http_method.dart';
import 'cwa_forecast_dto.dart';

/// CWA「一般天氣預報-今明 36 小時天氣預報」(F-C0032-001) 取得請求。
///
/// 每次搜尋對應一次呼叫，固定帶 `locationName` 查單一城市。
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

  @override
  CwaForecastResponseDto parseResponse(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw FormatException('CWA 回應不是 JSON 物件: ${response.runtimeType}');
    }
    return CwaForecastResponseDto.fromJson(response);
  }
}
