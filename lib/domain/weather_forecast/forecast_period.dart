/// 攝氏溫度區間。
class TemperatureRange {
  const TemperatureRange({required this.min, required this.max})
      : assert(min <= max, 'min 必須小於等於 max');

  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemperatureRange && other.min == min && other.max == max);

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => '$min°C – $max°C';
}

/// 降雨機率（百分比，0–100）。
class PrecipitationProbability {
  const PrecipitationProbability(this.value)
      : assert(value >= 0 && value <= 100, 'PoP 必須介於 0–100');

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrecipitationProbability && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value%';
}

/// 單一預報時段（CWA F-C0032-001 一筆通常為 12 小時）。
class ForecastPeriod {
  ForecastPeriod({
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.temperature,
    required this.precipitationProbability,
    required this.comfortIndex,
  }) {
    if (!startTime.isBefore(endTime)) {
      throw ArgumentError('startTime 必須早於 endTime');
    }
  }

  final DateTime startTime;
  final DateTime endTime;
  final String description; // 例：晴時多雲
  final TemperatureRange temperature;
  final PrecipitationProbability precipitationProbability;
  final String comfortIndex; // 例：舒適
}
