import '../network/api_request.dart';
import '../network/http_method.dart';
import 'cwa_forecast_dto.dart';

/// CWA「一般天氣預報-今明 36 小時天氣預報」(F-C0032-001) 取得請求。
///
/// [cityName] 可選：
///   - 給定 → 帶 `locationName=...`，CWA 回 1 筆
///   - 省略 → 不帶 `locationName`，CWA 回所有 22 縣市
class GetCwaForecastRequest extends ApiRequest<CwaForecastResponseDto> {
  GetCwaForecastRequest({
    this.cityName,
    required this.apiToken,
  });

  final String? cityName;
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
        if (cityName != null) 'locationName': cityName as String,
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
