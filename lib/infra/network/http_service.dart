import 'api_request.dart';

/// HTTP 服務介面。
///
/// Domain / Application / Repository 一律依賴此抽象，不直接依賴
/// 任何具體 HTTP client（如 Dio）。可用於：
/// - 在測試中以 fake / mock 注入
/// - 未來替換實作（例如改用 `package:http`）而不動上層程式碼
abstract class HttpService {
  /// 執行 [request] 並回傳經 [ApiRequest.parseResponse] 解析後的結果。
  ///
  /// 失敗時拋 [ApiException]，呼叫端（通常是 Repository）負責翻譯為
  /// 領域層的 `DomainFailure`。
  Future<T> execute<T>(ApiRequest<T> request);
}
