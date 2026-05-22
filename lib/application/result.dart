/// 簡易的 Result 型別，用於 Use Case 不以例外傳遞「業務預期錯誤」。
///
/// 兩個子型別：
/// - [Ok]：成功，攜帶領域回應
/// - [Err]：失敗，攜帶領域 Failure（不是 Dart Error / Exception）
///
/// 故意保持極簡：沒有 `map` / `flatMap` / `fold` 等 monad 操作；呼叫端用
/// `switch (result) { case Ok(...) => ...; case Err(...) => ...; }` 即可
/// 編譯時窮舉，需求成長到不夠用再加。
sealed class Result<T, E> {
  const Result();
}

class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, E> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

class Err<T, E> extends Result<T, E> {
  const Err(this.failure);
  final E failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Err<T, E> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
