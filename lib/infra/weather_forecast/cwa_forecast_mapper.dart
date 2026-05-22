import '../../core/utils/log.dart';
import '../../domain/weather_forecast/city_name.dart';
import '../../domain/weather_forecast/failure.dart';
import '../../domain/weather_forecast/forecast_period.dart';
import '../../domain/weather_forecast/weather_forecast.dart';
import 'cwa_forecast_dto.dart';

/// CWA DTO → 領域聚合 [WeatherForecast] 的轉換器。
///
/// 任何結構性錯誤一律以 [MalformedForecastDataError] 對外，避免將
/// `FormatException` / `TypeError` 洩漏至上層。所有失敗在丟出前都會
/// 透過 [Log.w] 紀錄原始細節，便於日後除錯。
class CwaForecastMapper {
  const CwaForecastMapper();

  /// 從 CWA 回應的某一個 location 區塊組出領域聚合。
  ///
  /// CWA 結構為 element × time（每個 weatherElement 內含 3 個時段），
  /// 此處 pivot 為 time × elements（每個時段彙整 Wx/PoP/MinT/MaxT/CI）。
  WeatherForecast toDomain({
    required CityName city,
    required CwaLocationDto location,
    required DateTime fetchedAt,
  }) {
    try {
      final byElement = {
        for (final e in location.weatherElements) e.elementName: e.times,
      };

      final wx = _requireElement(byElement, 'Wx');
      final pop = _requireElement(byElement, 'PoP');
      final minT = _requireElement(byElement, 'MinT');
      final maxT = _requireElement(byElement, 'MaxT');
      final ci = _requireElement(byElement, 'CI');

      final size = wx.length;
      if (size == 0) {
        _fail('Wx 時段為空');
      }
      if (pop.length != size ||
          minT.length != size ||
          maxT.length != size ||
          ci.length != size) {
        _fail('各 weatherElement 時段數不一致 '
            '(Wx=$size, PoP=${pop.length}, MinT=${minT.length}, '
            'MaxT=${maxT.length}, CI=${ci.length})');
      }

      final periods = <ForecastPeriod>[];
      for (var i = 0; i < size; i++) {
        periods.add(_buildPeriod(
          wxBlock: wx[i],
          popBlock: pop[i],
          minTBlock: minT[i],
          maxTBlock: maxT[i],
          ciBlock: ci[i],
        ));
      }

      return WeatherForecast(
        city: city,
        periods: periods,
        fetchedAt: fetchedAt,
      );
    } on MalformedForecastDataError {
      rethrow;
    } on FormatException catch (e, stackTrace) {
      Log.w('CwaForecastMapper: FormatException - ${e.message}');
      Log.w('stack: $stackTrace');
      throw MalformedForecastDataError(e.message);
    } catch (e, stackTrace) {
      Log.w('CwaForecastMapper: Unexpected error - $e');
      Log.w('stack: $stackTrace');
      throw MalformedForecastDataError(e.toString());
    }
  }

  List<CwaTimeBlockDto> _requireElement(
    Map<String, List<CwaTimeBlockDto>> map,
    String key,
  ) {
    final value = map[key];
    if (value == null) {
      _fail('缺少 weatherElement: $key');
    }
    return value;
  }

  ForecastPeriod _buildPeriod({
    required CwaTimeBlockDto wxBlock,
    required CwaTimeBlockDto popBlock,
    required CwaTimeBlockDto minTBlock,
    required CwaTimeBlockDto maxTBlock,
    required CwaTimeBlockDto ciBlock,
  }) {
    final start = _parseDateTime(wxBlock.startTime);
    final end = _parseDateTime(wxBlock.endTime);
    if (popBlock.startTime != wxBlock.startTime ||
        minTBlock.startTime != wxBlock.startTime ||
        maxTBlock.startTime != wxBlock.startTime ||
        ciBlock.startTime != wxBlock.startTime) {
      _fail('時段 ${wxBlock.startTime} 各元素時間未對齊');
    }

    // 注意：PoP / MinT / MaxT 的「數值」放在 parameterName 而非 parameterValue —
    // 詳見 CwaTimeBlockDto.parameterName 的 doc。
    final popValue = _parseInt(popBlock.parameterName, label: 'PoP');
    if (popValue < 0 || popValue > 100) {
      _fail('PoP 超出範圍: $popValue');
    }

    final minTValue = _parseInt(minTBlock.parameterName, label: 'MinT');
    final maxTValue = _parseInt(maxTBlock.parameterName, label: 'MaxT');
    if (minTValue > maxTValue) {
      _fail('MinT($minTValue) > MaxT($maxTValue)');
    }

    return ForecastPeriod(
      startTime: start,
      endTime: end,
      description: wxBlock.parameterName,
      temperature: TemperatureRange(min: minTValue, max: maxTValue),
      precipitationProbability: PrecipitationProbability(popValue),
      comfortIndex: ciBlock.parameterName,
    );
  }

  DateTime _parseDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      _fail('時間格式無法解析: $raw');
    }
    return parsed;
  }

  int _parseInt(String raw, {required String label}) {
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _fail('$label 無法轉為整數: $raw');
    }
    return parsed;
  }

  /// 統一 log + throw 入口；確保所有 [MalformedForecastDataError]
  /// 在拋出前都有原始細節留底。
  Never _fail(String detail) {
    Log.w('CwaForecastMapper: $detail');
    throw MalformedForecastDataError(detail);
  }
}
