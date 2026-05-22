/// WeatherForecast 上下文的領域失敗類型。
///
/// 所有來自 Infra / Use Case 的可預期失敗都包裝為 [DomainFailure] 的子型別，
/// 確保 Presentation 層只需 switch 一個 sealed type 即可窮舉。
sealed class DomainFailure implements Exception {
  const DomainFailure();
}

/// 輸入的城市名稱不合法（空字串、過長、含非法字元）。
class InvalidCityNameError extends DomainFailure {
  const InvalidCityNameError(this.reason);
  final String reason;

  @override
  String toString() => 'InvalidCityNameError: $reason';
}

/// API 回傳成功但找不到對應城市的預報資料。
class CityNotFoundError extends DomainFailure {
  const CityNotFoundError(this.cityName);
  final String cityName;

  @override
  String toString() => 'CityNotFoundError: $cityName';
}

/// API 回傳格式不符合預期（缺欄位、型別錯、結構錯）。
class MalformedForecastDataError extends DomainFailure {
  const MalformedForecastDataError(this.detail);
  final String detail;

  @override
  String toString() => 'MalformedForecastDataError: $detail';
}

/// 網路連線無法建立（裝置離線、DNS 失敗、SSL 失敗等）。
class NetworkUnavailableError extends DomainFailure {
  const NetworkUnavailableError();

  @override
  String toString() => 'NetworkUnavailableError';
}

/// 遠端服務回應錯誤狀態碼。
class RemoteServiceError extends DomainFailure {
  const RemoteServiceError({this.statusCode});
  final int? statusCode;

  @override
  String toString() => 'RemoteServiceError(statusCode: $statusCode)';
}
