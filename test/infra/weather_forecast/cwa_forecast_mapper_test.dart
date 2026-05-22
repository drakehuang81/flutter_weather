import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';
import 'package:flutter_weather/infra/weather_forecast/cwa_forecast_dto.dart';
import 'package:flutter_weather/infra/weather_forecast/cwa_forecast_mapper.dart';

import '../../fixtures/cwa_forecast_fixtures.dart';

CwaLocationDto _firstLocation(String rawJson) {
  final dto = CwaForecastResponseDto.fromJson(
    jsonDecode(rawJson) as Map<String, dynamic>,
  );
  return dto.locations.first;
}

void main() {
  const mapper = CwaForecastMapper();
  final city = CityName('臺北市');
  final fetchedAt = DateTime(2026, 5, 22, 11);

  group('happy path', () {
    test('產生三個依時間排序的 ForecastPeriod', () {
      final forecast = mapper.toDomain(
        city: city,
        location: _firstLocation(taipeiSuccessJson),
        fetchedAt: fetchedAt,
      );

      expect(forecast.city, city);
      expect(forecast.periods, hasLength(3));
      expect(forecast.periods.first.description, '晴時多雲');
      expect(forecast.periods.first.temperature.min, 24);
      expect(forecast.periods.first.temperature.max, 30);
      expect(forecast.periods.first.precipitationProbability.value, 10);
      expect(forecast.periods.first.comfortIndex, '舒適');
    });

    test('startTime 正確解析為本地時間 DateTime', () {
      final forecast = mapper.toDomain(
        city: city,
        location: _firstLocation(taipeiSuccessJson),
        fetchedAt: fetchedAt,
      );
      expect(forecast.periods.first.startTime, DateTime(2026, 5, 22, 12));
    });
  });

  group('error path', () {
    test('PoP 為非數字字串：拋 MalformedForecastDataError', () {
      final location = _firstLocation(_buildSingleBlockLocation(popName: 'abc'));
      expect(
        () => mapper.toDomain(
          city: city,
          location: location,
          fetchedAt: fetchedAt,
        ),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });

    test('MinT 為非數字字串：拋 MalformedForecastDataError', () {
      final location = _firstLocation(malformedNonNumericMinTJson);
      expect(
        () => mapper.toDomain(
          city: city,
          location: location,
          fetchedAt: fetchedAt,
        ),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });

    test('PoP 超出 0–100：拋 MalformedForecastDataError', () {
      final location = _firstLocation(_buildSingleBlockLocation(popName: '150'));
      expect(
        () => mapper.toDomain(
          city: city,
          location: location,
          fetchedAt: fetchedAt,
        ),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });

    test('缺 Wx 元素：拋 MalformedForecastDataError', () {
      final location = _firstLocation(_buildLocationWithoutElement('Wx'));
      expect(
        () => mapper.toDomain(
          city: city,
          location: location,
          fetchedAt: fetchedAt,
        ),
        throwsA(isA<MalformedForecastDataError>()),
      );
    });
  });
}

const _start = '2026-05-22 12:00:00';
const _end = '2026-05-22 18:00:00';

String _block({required String name, String? unit, String? value}) {
  final unitField = unit != null ? ',"parameterUnit":"$unit"' : '';
  final valueField = value != null ? ',"parameterValue":"$value"' : '';
  return '{"startTime":"$_start","endTime":"$_end","parameter":{"parameterName":"$name"$valueField$unitField}}';
}

/// 產生只含 1 個時段的 location JSON，方便聚焦測試。
String _buildSingleBlockLocation({String popName = '10'}) => '''
{
  "success": "true",
  "records": {
    "location": [{
      "locationName": "臺北市",
      "weatherElement": [
        {"elementName":"Wx","time":[${_block(name: '晴', value: '1')}]},
        {"elementName":"PoP","time":[${_block(name: popName, unit: '百分比')}]},
        {"elementName":"MinT","time":[${_block(name: '20', unit: 'C')}]},
        {"elementName":"MaxT","time":[${_block(name: '30', unit: 'C')}]},
        {"elementName":"CI","time":[${_block(name: '舒適')}]}
      ]
    }]
  }
}
''';

/// 產生缺少指定 weatherElement 的 location JSON。
String _buildLocationWithoutElement(String missingName) {
  const all = ['Wx', 'PoP', 'MinT', 'MaxT', 'CI'];
  final remain = all.where((e) => e != missingName);
  final elements = remain.map((name) {
    final isNumeric = name == 'PoP' || name == 'MinT' || name == 'MaxT';
    return '{"elementName":"$name","time":[${_block(name: isNumeric ? '20' : '晴', unit: isNumeric ? 'C' : null)}]}';
  }).join(',');
  return '''
{
  "success": "true",
  "records": {
    "location": [{
      "locationName": "臺北市",
      "weatherElement": [$elements]
    }]
  }
}
''';
}
