import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/weather_forecast/city_name.dart';
import 'package:flutter_weather/domain/weather_forecast/failure.dart';

void main() {
  group('CityName', () {
    test('合法輸入：建構成功且 trim 兩端空白', () {
      final city = CityName('  臺北市  ');
      expect(city.value, '臺北市');
    });

    test('空字串：拋 InvalidCityNameError', () {
      expect(() => CityName(''), throwsA(isA<InvalidCityNameError>()));
    });

    test('全空白：拋 InvalidCityNameError', () {
      expect(() => CityName('   '), throwsA(isA<InvalidCityNameError>()));
    });

    test('超過 20 字：拋 InvalidCityNameError', () {
      expect(
        () => CityName('A' * 21),
        throwsA(isA<InvalidCityNameError>()),
      );
    });

    test('內含換行字元：拋 InvalidCityNameError', () {
      expect(
        () => CityName('臺北\n市'),
        throwsA(isA<InvalidCityNameError>()),
      );
    });

    test('tryParse：合法回 CityName', () {
      expect(CityName.tryParse('高雄市')?.value, '高雄市');
    });

    test('tryParse：違規回 null', () {
      expect(CityName.tryParse(''), isNull);
      expect(CityName.tryParse('A' * 30), isNull);
    });

    test('值相等性：相同 value → 相等', () {
      expect(CityName('臺北市'), equals(CityName('臺北市')));
      expect(CityName('臺北市').hashCode, equals(CityName('臺北市').hashCode));
    });
  });
}
