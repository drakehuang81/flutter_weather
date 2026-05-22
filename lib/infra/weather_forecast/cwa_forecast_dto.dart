/// CWA F-C0032-001 回應的 DTO。
///
/// 對應 `format=JSON` 的實際回應結構：
/// ```
/// {
///   "success": "true",
///   "records": {
///     "datasetDescription": "...",
///     "location": [ { "locationName": ..., "weatherElement": [...] } ]
///   }
/// }
/// ```
///
/// 僅與遠端 JSON 結構耦合；不含任何業務不變式，由 Mapper 負責轉成領域型別。
class CwaForecastResponseDto {
  CwaForecastResponseDto({required this.success, required this.locations});

  /// CWA 頂層 `success` 旗標（字串 "true" / "false"）。
  ///
  /// 經實測：token 錯誤會以 HTTP 401 回應而非 200+success="false"，但 CWA
  /// 仍保留此欄位供 rate limit / 參數錯誤等情境使用，因此 Repository 仍會
  /// 防禦性檢查 `success != "true"`。
  final String success;

  /// `records.location[]`，每筆對應一個 `locationName`。
  final List<CwaLocationDto> locations;

  factory CwaForecastResponseDto.fromJson(Map<String, dynamic> json) {
    final success = json['success'];
    if (success is! String) {
      throw const FormatException('success 缺失或非字串');
    }
    if (success != 'true') {
      return CwaForecastResponseDto(success: success, locations: const []);
    }
    final records = json['records'];
    if (records is! Map<String, dynamic>) {
      throw const FormatException('records 缺失或型別不符');
    }
    final rawLocations = records['location'];
    if (rawLocations is! List) {
      throw const FormatException('records.location 不是陣列');
    }
    return CwaForecastResponseDto(
      success: success,
      locations: rawLocations
          .whereType<Map<String, dynamic>>()
          .map(CwaLocationDto.fromJson)
          .toList(growable: false),
    );
  }
}

class CwaLocationDto {
  CwaLocationDto({required this.locationName, required this.weatherElements});

  final String locationName;
  final List<CwaWeatherElementDto> weatherElements;

  factory CwaLocationDto.fromJson(Map<String, dynamic> json) {
    final name = json['locationName'];
    final rawElements = json['weatherElement'];
    if (name is! String) {
      throw const FormatException('location.locationName 缺失或非字串');
    }
    if (rawElements is! List) {
      throw const FormatException('location.weatherElement 不是陣列');
    }
    return CwaLocationDto(
      locationName: name,
      weatherElements: rawElements
          .whereType<Map<String, dynamic>>()
          .map(CwaWeatherElementDto.fromJson)
          .toList(growable: false),
    );
  }
}

class CwaWeatherElementDto {
  CwaWeatherElementDto({required this.elementName, required this.times});

  /// 如 `Wx` / `PoP` / `MinT` / `MaxT` / `CI`
  final String elementName;
  final List<CwaTimeBlockDto> times;

  factory CwaWeatherElementDto.fromJson(Map<String, dynamic> json) {
    final name = json['elementName'];
    final rawTimes = json['time'];
    if (name is! String) {
      throw const FormatException('weatherElement.elementName 缺失或非字串');
    }
    if (rawTimes is! List) {
      throw const FormatException('weatherElement.time 不是陣列');
    }
    return CwaWeatherElementDto(
      elementName: name,
      times: rawTimes
          .whereType<Map<String, dynamic>>()
          .map(CwaTimeBlockDto.fromJson)
          .toList(growable: false),
    );
  }
}

class CwaTimeBlockDto {
  CwaTimeBlockDto({
    required this.startTime,
    required this.endTime,
    required this.parameterName,
    this.parameterValue,
    this.parameterUnit,
  });

  /// CWA 格式（無 T、無時區），例：`"2026-05-22 12:00:00"`。
  /// `DateTime.tryParse` 仍可正確解析為本地時間。
  final String startTime;
  final String endTime;

  /// CWA quirk：本欄位**永遠是「主要值」**，型別會隨 elementName 變化：
  ///   - `Wx`   → 中文描述（例：「晴時多雲」）；圖示代碼在 [parameterValue]
  ///   - `PoP`  → 數值字串（例：「20」）；單位在 [parameterUnit]（「百分比」）
  ///   - `MinT` / `MaxT` → 數值字串（例：「23」）；單位在 [parameterUnit]（「C」）
  ///   - `CI`   → 中文描述（例：「悶熱」）
  ///
  /// 換言之 Mapper 必須對「數值類 element」直接從本欄位呼叫 `int.parse`，
  /// 看起來像 bug 但實際上是 CWA API 設計。請勿改用 [parameterValue]。
  final String parameterName;
  final String? parameterValue;
  final String? parameterUnit;

  factory CwaTimeBlockDto.fromJson(Map<String, dynamic> json) {
    final start = json['startTime'];
    final end = json['endTime'];
    final parameter = json['parameter'];
    if (start is! String || end is! String) {
      throw const FormatException('time.startTime/endTime 缺失或非字串');
    }
    if (parameter is! Map<String, dynamic>) {
      throw const FormatException('time.parameter 缺失或型別不符');
    }
    final parameterName = parameter['parameterName'];
    if (parameterName is! String) {
      throw const FormatException('parameter.parameterName 缺失或非字串');
    }
    return CwaTimeBlockDto(
      startTime: start,
      endTime: end,
      parameterName: parameterName,
      parameterValue: parameter['parameterValue'] as String?,
      parameterUnit: parameter['parameterUnit'] as String?,
    );
  }
}
