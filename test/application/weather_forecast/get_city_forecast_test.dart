import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/application/result.dart';
import 'package:flutter_weather/application/weather_forecast/get_city_forecast.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';
import 'package:flutter_weather/domain/weather_forecast/forecast_period.dart';
import 'package:flutter_weather/domain/weather_forecast/weather_forecast.dart';
import 'package:flutter_weather/domain/weather_forecast/weather_forecast_repository.dart';

class _StubRepo implements WeatherForecastRepository {
  _StubRepo({required this.specific, required this.all});
  final WeatherForecast specific;
  final List<WeatherForecast> all;

  @override
  Future<List<WeatherForecast>> fetchForecasts({CityName? city}) async {
    if (city != null) return [specific];
    return all;
  }
}

class _ThrowingRepo implements WeatherForecastRepository {
  _ThrowingRepo(this.failure);
  final DomainFailure failure;

  @override
  Future<List<WeatherForecast>> fetchForecasts({CityName? city}) async =>
      throw failure;
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
  group('GetCityForecast — 指定城市', () {
    test('合法輸入 + repo 成功 → Ok([forecast])', () async {
      final city = CityName('臺北市');
      final expected = _stub(city);
      final useCase = GetCityForecast(
        _StubRepo(specific: expected, all: [_stub(CityName('高雄市'))]),
      );

      final result = await useCase('  臺北市  ');

      final list = (result as Ok).value as List<WeatherForecast>;
      expect(list, hasLength(1));
      expect(list.first, expected);
    });

    test('超長輸入 → Err(InvalidCityNameError)', () async {
      final useCase = GetCityForecast(
        _StubRepo(specific: _stub(CityName('x')), all: const []),
      );
      final result = await useCase('A' * 50);
      expect((result as Err).failure, isA<InvalidCityNameError>());
    });

    test('repo 拋 CityNotFoundError → Err', () async {
      final useCase =
          GetCityForecast(_ThrowingRepo(const CityNotFoundError('火星市')));
      final result = await useCase('火星市');
      expect((result as Err).failure, isA<CityNotFoundError>());
    });
  });

  group('GetCityForecast — 瀏覽模式（空輸入）', () {
    test('空字串 → repo.fetchForecasts() → Ok(all)', () async {
      final all = [_stub(CityName('臺北市')), _stub(CityName('高雄市'))];
      final useCase = GetCityForecast(
        _StubRepo(specific: _stub(CityName('x')), all: all),
      );

      final result = await useCase('');

      final list = (result as Ok).value as List<WeatherForecast>;
      expect(list, hasLength(2));
      expect(list.map((f) => f.city.value), containsAll(['臺北市', '高雄市']));
    });

    test('全空白 → 同樣走瀏覽模式', () async {
      final all = [_stub(CityName('臺北市'))];
      final useCase = GetCityForecast(
        _StubRepo(specific: _stub(CityName('x')), all: all),
      );

      final result = await useCase('   ');

      final list = (result as Ok).value as List<WeatherForecast>;
      expect(list, hasLength(1));
    });

    test('repo 拋 NetworkUnavailableError → Err', () async {
      final useCase =
          GetCityForecast(_ThrowingRepo(const NetworkUnavailableError()));
      final result = await useCase('');
      expect((result as Err).failure, isA<NetworkUnavailableError>());
    });
  });

  group('GetCityForecast — Failure routing', () {
    test('RemoteServiceError → 保留 statusCode', () async {
      final useCase = GetCityForecast(
        _ThrowingRepo(const RemoteServiceError(statusCode: 401)),
      );
      final result = await useCase('臺北市');
      final failure = (result as Err).failure as RemoteServiceError;
      expect(failure.statusCode, 401);
    });

    test('MalformedForecastDataError → Err', () async {
      final useCase = GetCityForecast(
        _ThrowingRepo(const MalformedForecastDataError('bad')),
      );
      final result = await useCase('臺北市');
      expect((result as Err).failure, isA<MalformedForecastDataError>());
    });
  });
}
