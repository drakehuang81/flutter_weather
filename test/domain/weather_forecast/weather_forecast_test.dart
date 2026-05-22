import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/forecast_period.dart';
import 'package:flutter_weather/domain/weather_forecast/weather_forecast.dart';

ForecastPeriod _period(int hourStart) => ForecastPeriod(
      startTime: DateTime(2026, 5, 22, hourStart),
      endTime: DateTime(2026, 5, 22, hourStart + 6),
      description: '晴',
      temperature: TemperatureRange(min: 20, max: 30),
      precipitationProbability: PrecipitationProbability(10),
      comfortIndex: '舒適',
    );

void main() {
  group('WeatherForecast', () {
    final city = CityName('臺北市');
    final fetchedAt = DateTime(2026, 5, 22, 11);

    test('periods 為空：拋 ArgumentError', () {
      expect(
        () => WeatherForecast(city: city, periods: [], fetchedAt: fetchedAt),
        throwsArgumentError,
      );
    });

    test('periods 不變式：建構後依 startTime 升冪排序', () {
      final out = WeatherForecast(
        city: city,
        periods: [_period(18), _period(6), _period(12)],
        fetchedAt: fetchedAt,
      );
      expect(
        out.periods.map((p) => p.startTime.hour).toList(),
        [6, 12, 18],
      );
    });

    test('periods 不變式：回傳清單為 unmodifiable', () {
      final out = WeatherForecast(
        city: city,
        periods: [_period(6)],
        fetchedAt: fetchedAt,
      );
      expect(() => out.periods.add(_period(12)), throwsUnsupportedError);
    });
  });
}
