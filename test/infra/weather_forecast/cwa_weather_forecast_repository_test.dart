import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';
import 'package:flutter_weather/infra/network/api_exception.dart';
import 'package:flutter_weather/infra/network/api_request.dart';
import 'package:flutter_weather/infra/network/http_service.dart';
import 'package:flutter_weather/infra/weather_forecast/cwa_weather_forecast_repository.dart';

import '../../fixtures/cwa_forecast_fixtures.dart';

/// 直接回傳預錄 JSON Map 的 fake，等同 stub server。
class _StubHttpService implements HttpService {
  _StubHttpService(this.rawJson);
  final String rawJson;

  @override
  Future<T> execute<T>(ApiRequest<T> request) async {
    final json = jsonDecode(rawJson);
    return request.parseResponse(json);
  }
}

/// 觸發指定 ApiException 的 fake。
class _ThrowingHttpService implements HttpService {
  _ThrowingHttpService(this.error);
  final ApiException error;

  @override
  Future<T> execute<T>(ApiRequest<T> request) async => throw error;
}

void main() {
  final city = CityName('臺北市');
  final clock = DateTime(2026, 5, 22, 11);

  CwaWeatherForecastRepository buildRepo(HttpService http) =>
      CwaWeatherForecastRepository(
        httpService: http,
        apiToken: 'TEST-TOKEN',
        clock: () => clock,
      );

  group('happy path', () {
    test('成功取得 WeatherForecast 並通過聚合不變式', () async {
      final repo = buildRepo(_StubHttpService(taipeiSuccessJson));
      final forecast = await repo.fetchByCity(city);

      expect(forecast.city, city);
      expect(forecast.periods, hasLength(3));
      expect(forecast.fetchedAt, clock);
    });
  });

  group('translates ApiException', () {
    test('isNetworkError → NetworkUnavailableError', () async {
      final repo = buildRepo(_ThrowingHttpService(ApiException('offline')));
      await expectLater(
        repo.fetchByCity(city),
        throwsA(isA<NetworkUnavailableError>()),
      );
    });

    test('帶 statusCode → RemoteServiceError(statusCode)', () async {
      final repo = buildRepo(
        _ThrowingHttpService(ApiException('500', statusCode: 500)),
      );
      await expectLater(
        repo.fetchByCity(city),
        throwsA(
          isA<RemoteServiceError>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('handles CWA 200 變體', () {
    test('success="false" → RemoteServiceError(statusCode: 200)', () async {
      final repo = buildRepo(_StubHttpService(authFailureJson));
      await expectLater(
        repo.fetchByCity(city),
        throwsA(
          isA<RemoteServiceError>()
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('records.location 為空 → CityNotFoundError', () async {
      final repo = buildRepo(_StubHttpService(emptyLocationsJson));
      await expectLater(
        repo.fetchByCity(city),
        throwsA(isA<CityNotFoundError>()),
      );
    });

    test('locationName 不匹配 → CityNotFoundError', () async {
      final repo = buildRepo(_StubHttpService(taipeiSuccessJson));
      await expectLater(
        repo.fetchByCity(CityName('高雄市')),
        throwsA(isA<CityNotFoundError>()),
      );
    });

    test('缺 records → MalformedForecastDataError', () async {
      final repo = buildRepo(_StubHttpService(malformedNoRecordsJson));
      await expectLater(
        repo.fetchByCity(city),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });
  });
}
