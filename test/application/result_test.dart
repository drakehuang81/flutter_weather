import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/application/result.dart';

void main() {
  group('Result', () {
    test('Ok 攜帶值且支援 switch 窮舉', () {
      const Result<int, String> r = Ok(42);
      final out = switch (r) {
        Ok(value: final v) => 'ok=$v',
        Err(failure: final f) => 'err=$f',
      };
      expect(out, 'ok=42');
    });

    test('Err 攜帶 failure 且支援 switch 窮舉', () {
      const Result<int, String> r = Err('boom');
      final out = switch (r) {
        Ok(value: final v) => 'ok=$v',
        Err(failure: final f) => 'err=$f',
      };
      expect(out, 'err=boom');
    });

    test('值相等性', () {
      expect(const Ok<int, String>(1), equals(const Ok<int, String>(1)));
      expect(const Err<int, String>('x'), equals(const Err<int, String>('x')));
      expect(const Ok<int, String>(1), isNot(equals(const Ok<int, String>(2))));
    });
  });
}
