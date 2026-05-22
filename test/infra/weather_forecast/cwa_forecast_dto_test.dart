import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/infra/weather_forecast/cwa_forecast_dto.dart';

import '../../fixtures/cwa_forecast_fixtures.dart';

Map<String, dynamic> _decode(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  group('CwaForecastResponseDto.fromJson', () {
    test('happy path：解出 success=true 與 location 清單', () {
      final dto = CwaForecastResponseDto.fromJson(_decode(taipeiSuccessJson));
      expect(dto.success, 'true');
      expect(dto.locations, hasLength(1));
      expect(dto.locations.first.locationName, '臺北市');
      expect(dto.locations.first.weatherElements, hasLength(5));
    });

    test('success="false"：不拋例外，回傳空 location 清單', () {
      final dto = CwaForecastResponseDto.fromJson(_decode(authFailureJson));
      expect(dto.success, 'false');
      expect(dto.locations, isEmpty);
    });

    test('records.location 為空陣列：合法', () {
      final dto = CwaForecastResponseDto.fromJson(_decode(emptyLocationsJson));
      expect(dto.success, 'true');
      expect(dto.locations, isEmpty);
    });

    test('缺 records：拋 FormatException', () {
      expect(
        () => CwaForecastResponseDto.fromJson(_decode(malformedNoRecordsJson)),
        throwsA(isA<FormatException>()),
      );
    });

    test('缺 success 欄位：拋 FormatException', () {
      expect(
        () => CwaForecastResponseDto.fromJson({}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CwaTimeBlockDto.fromJson', () {
    test('正確結構：parameterName / value / unit 各就各位', () {
      final block = CwaTimeBlockDto.fromJson({
        'startTime': '2026-05-22 12:00:00',
        'endTime': '2026-05-22 18:00:00',
        'parameter': {
          'parameterName': '晴時多雲',
          'parameterValue': '2',
        },
      });
      expect(block.parameterName, '晴時多雲');
      expect(block.parameterValue, '2');
      expect(block.parameterUnit, isNull);
    });

    test('缺 parameter：拋 FormatException', () {
      expect(
        () => CwaTimeBlockDto.fromJson({
          'startTime': '2026-05-22 12:00:00',
          'endTime': '2026-05-22 18:00:00',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
