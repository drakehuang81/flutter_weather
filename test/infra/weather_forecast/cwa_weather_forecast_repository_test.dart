import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';
import 'package:flutter_weather/infra/network/api_exception.dart';
import 'package:flutter_weather/infra/network/api_request.dart';
import 'package:flutter_weather/infra/network/http_service.dart';
import 'package:flutter_weather/infra/weather_forecast/cwa_weather_forecast_repository.dart';

import '../../fixtures/cwa_forecast_fixtures.dart';

class _StubHttpService implements HttpService {
  _StubHttpService(this.rawJson);
  final String rawJson;

  @override
  Future<T> execute<T>(ApiRequest<T> request) async {
    final json = jsonDecode(rawJson);
    return request.parseResponse(json);
  }
}

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

  group('fetchForecasts(city: ...)', () {
    test('成功取得 1-element list', () async {
      final repo = buildRepo(_StubHttpService(taipeiSuccessJson));
      final list = await repo.fetchForecasts(city: city);
      expect(list, hasLength(1));
      expect(list.first.city, city);
      expect(list.first.periods, hasLength(3));
      expect(list.first.fetchedAt, clock);
    });

    test('success="false" → RemoteServiceError(200)', () async {
      final repo = buildRepo(_StubHttpService(authFailureJson));
      await expectLater(
        repo.fetchForecasts(city: city),
        throwsA(
          isA<RemoteServiceError>()
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('location 為空 → CityNotFoundError', () async {
      final repo = buildRepo(_StubHttpService(emptyLocationsJson));
      await expectLater(
        repo.fetchForecasts(city: city),
        throwsA(isA<CityNotFoundError>()),
      );
    });

    test('locationName 不匹配 → CityNotFoundError', () async {
      final repo = buildRepo(_StubHttpService(taipeiSuccessJson));
      await expectLater(
        repo.fetchForecasts(city: CityName('高雄市')),
        throwsA(isA<CityNotFoundError>()),
      );
    });

    test('缺 records → MalformedForecastDataError', () async {
      final repo = buildRepo(_StubHttpService(malformedNoRecordsJson));
      await expectLater(
        repo.fetchForecasts(city: city),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });
  });

  group('fetchForecasts() — 瀏覽模式', () {
    test('成功回所有縣市', () async {
      final repo = buildRepo(_StubHttpService(twoCitiesSuccessJson));
      final list = await repo.fetchForecasts();
      expect(list, hasLength(2));
      expect(list.map((f) => f.city.value), containsAll(['臺北市', '高雄市']));
      expect(list.every((f) => f.fetchedAt == clock), isTrue);
    });

    test('location 為空 → 空 list（不視為錯誤）', () async {
      final repo = buildRepo(_StubHttpService(emptyLocationsJson));
      final list = await repo.fetchForecasts();
      expect(list, isEmpty);
    });

    test('success="false" → RemoteServiceError(200)', () async {
      final repo = buildRepo(_StubHttpService(authFailureJson));
      await expectLater(
        repo.fetchForecasts(),
        throwsA(isA<RemoteServiceError>()),
      );
    });
  });

  group('translates ApiException', () {
    test('isNetworkError → NetworkUnavailableError', () async {
      final repo = buildRepo(_ThrowingHttpService(ApiException('offline')));
      await expectLater(
        repo.fetchForecasts(city: city),
        throwsA(isA<NetworkUnavailableError>()),
      );
      await expectLater(
        repo.fetchForecasts(),
        throwsA(isA<NetworkUnavailableError>()),
      );
    });

    test('帶 statusCode → RemoteServiceError(statusCode)', () async {
      final repo = buildRepo(
        _ThrowingHttpService(ApiException('500', statusCode: 500)),
      );
      await expectLater(
        repo.fetchForecasts(city: city),
        throwsA(
          isA<RemoteServiceError>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
