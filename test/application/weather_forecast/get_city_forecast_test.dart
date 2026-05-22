import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/application/result.dart';
import 'package:flutter_weather/application/weather_forecast/get_city_forecast.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';
import 'package:flutter_weather/domain/weather_forecast/forecast_period.dart';
import 'package:flutter_weather/domain/weather_forecast/weather_forecast.dart';
import 'package:flutter_weather/domain/weather_forecast/weather_forecast_repository.dart';

class _StubRepo implements WeatherForecastRepository {
  _StubRepo(this.forecast);
  final WeatherForecast forecast;

  @override
  Future<WeatherForecast> fetchByCity(CityName city) async => forecast;
}

class _ThrowingRepo implements WeatherForecastRepository {
  _ThrowingRepo(this.failure);
  final DomainFailure failure;

  @override
  Future<WeatherForecast> fetchByCity(CityName city) async => throw failure;
}

WeatherForecast _stub(CityName city) => WeatherForecast(
      city: city,
      fetchedAt: DateTime(2026, 5, 22, 11),
      periods: [
        ForecastPeriod(
          startTime: DateTime(2026, 5, 22, 12),
          endTime: DateTime(2026, 5, 22, 18),
          description: '晴',
          temperature: TemperatureRange(min: 24, max: 30),
          precipitationProbability: PrecipitationProbability(10),
          comfortIndex: '舒適',
        ),
      ],
    );

void main() {
  group('GetCityForecast', () {
    test('合法輸入 + repo 成功 → Ok(forecast)', () async {
      final city = CityName('臺北市');
      final expected = _stub(city);
      final useCase = GetCityForecast(_StubRepo(expected));

      final result = await useCase('  臺北市  ');

      expect((result as Ok).value, expected);
    });

    test('空字串輸入 → Err(InvalidCityNameError)', () async {
      final useCase = GetCityForecast(_StubRepo(_stub(CityName('x'))));
      final result = await useCase('   ');
      expect((result as Err).failure, isA<InvalidCityNameError>());
    });

    test('超長輸入 → Err(InvalidCityNameError)', () async {
      final useCase = GetCityForecast(_StubRepo(_stub(CityName('x'))));
      final result = await useCase('A' * 50);
      expect((result as Err).failure, isA<InvalidCityNameError>());
    });

    test('repo 拋 CityNotFoundError → Err(CityNotFoundError)', () async {
      final useCase =
          GetCityForecast(_ThrowingRepo(const CityNotFoundError('火星市')));
      final result = await useCase('火星市');
      expect((result as Err).failure, isA<CityNotFoundError>());
    });

    test('repo 拋 NetworkUnavailableError → Err', () async {
      final useCase =
          GetCityForecast(_ThrowingRepo(const NetworkUnavailableError()));
      final result = await useCase('臺北市');
      expect((result as Err).failure, isA<NetworkUnavailableError>());
    });

    test('repo 拋 RemoteServiceError → 保留 statusCode', () async {
      final useCase = GetCityForecast(
        _ThrowingRepo(const RemoteServiceError(statusCode: 401)),
      );
      final result = await useCase('臺北市');
      final failure = (result as Err).failure as RemoteServiceError;
      expect(failure.statusCode, 401);
    });

    test('repo 拋 MalformedForecastDataError → Err', () async {
      final useCase = GetCityForecast(
        _ThrowingRepo(const MalformedForecastDataError('bad')),
      );
      final result = await useCase('臺北市');
      expect((result as Err).failure, isA<MalformedForecastDataError>());
    });
  });
}
