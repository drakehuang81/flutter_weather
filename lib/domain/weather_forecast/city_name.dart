import 'failure.dart';

/// 城市名稱 Value Object。
///
/// 不變式：trim 後非空、長度 1–20、不含換行字元。
class CityName {
  CityName._(this.value);

  final String value;

  static const int maxLength = 20;

  /// 嚴格建構：違反不變式即拋 [InvalidCityNameError]。
  factory CityName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const InvalidCityNameError('城市名稱不可為空');
    }
    if (trimmed.length > maxLength) {
      throw InvalidCityNameError('城市名稱長度不可超過 $maxLength 字');
    }
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      throw const InvalidCityNameError('城市名稱不可包含換行字元');
    }
    return CityName._(trimmed);
  }

  /// 寬容建構：違反不變式時回傳 `null`，由呼叫端決定是否抛例外。
  static CityName? tryParse(String raw) {
    try {
      return CityName(raw);
    } on InvalidCityNameError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityName && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
