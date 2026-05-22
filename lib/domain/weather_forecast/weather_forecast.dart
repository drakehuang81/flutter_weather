import 'city_name.dart';
import 'forecast_period.dart';

/// 城市天氣預報聚合根。
///
/// 不變式：
/// - [periods] 非空
/// - [periods] 依 `startTime` 升冪排序
class WeatherForecast {
  WeatherForecast({
    required this.city,
    required List<ForecastPeriod> periods,
    required this.fetchedAt,
  }) : periods = List.unmodifiable(_sorted(periods)) {
    if (periods.isEmpty) {
      throw ArgumentError('WeatherForecast 至少需要 1 筆 ForecastPeriod');
    }
  }

  final CityName city;
  final List<ForecastPeriod> periods;
  final DateTime fetchedAt;

  static List<ForecastPeriod> _sorted(List<ForecastPeriod> input) {
    final copy = [...input];
    copy.sort((a, b) => a.startTime.compareTo(b.startTime));
    return copy;
  }
}
