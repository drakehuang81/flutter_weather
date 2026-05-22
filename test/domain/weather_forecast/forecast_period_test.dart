import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/forecast_period.dart';

void main() {
  group('TemperatureRange', () {
    test('min == max：允許（同溫）', () {
      final t = TemperatureRange(min: 25, max: 25);
      expect(t.min, 25);
      expect(t.max, 25);
    });

    test('min > max：assertion error', () {
      expect(
        () => TemperatureRange(min: 30, max: 20),
        throwsA(isA<AssertionError>()),
      );
    });

    test('值相等性', () {
      expect(
        TemperatureRange(min: 20, max: 30),
        equals(TemperatureRange(min: 20, max: 30)),
      );
    });
  });

  group('PrecipitationProbability', () {
    test('0 / 100 邊界值：允許', () {
      expect(PrecipitationProbability(0).value, 0);
      expect(PrecipitationProbability(100).value, 100);
    });

    test('小於 0：assertion error', () {
      expect(
        () => PrecipitationProbability(-1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('大於 100：assertion error', () {
      expect(
        () => PrecipitationProbability(101),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ForecastPeriod', () {
    final start = DateTime(2026, 5, 22, 12);
    final end = DateTime(2026, 5, 22, 18);

    test('合法時段：建構成功', () {
      final p = ForecastPeriod(
        startTime: start,
        endTime: end,
        description: '晴',
        temperature: TemperatureRange(min: 20, max: 30),
        precipitationProbability: PrecipitationProbability(10),
        comfortIndex: '舒適',
      );
      expect(p.description, '晴');
    });

    test('start == end：拋 ArgumentError', () {
      expect(
        () => ForecastPeriod(
          startTime: start,
          endTime: start,
          description: '晴',
          temperature: TemperatureRange(min: 20, max: 30),
          precipitationProbability: PrecipitationProbability(10),
          comfortIndex: '舒適',
        ),
        throwsArgumentError,
      );
    });

    test('start > end：拋 ArgumentError', () {
      expect(
        () => ForecastPeriod(
          startTime: end,
          endTime: start,
          description: '晴',
          temperature: TemperatureRange(min: 20, max: 30),
          precipitationProbability: PrecipitationProbability(10),
          comfortIndex: '舒適',
        ),
        throwsArgumentError,
      );
    });
  });
}
