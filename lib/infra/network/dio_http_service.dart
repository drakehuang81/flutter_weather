import 'package:dio/dio.dart';
import '../../core/utils/log.dart';
import 'api_exception.dart';
import 'api_request.dart';
import 'http_method.dart';
import 'http_service.dart';

/// [HttpService] 的 Dio 實作。
///
/// 攔截器、超時、Dio 例外翻譯為 [ApiException] 都封閉在此檔內；
/// 上層只看見 [HttpService] 介面與 [ApiException]，不感知 Dio 存在。
class DioHttpService implements HttpService {
  DioHttpService({
    Dio? dio,
    Duration defaultTimeout = const Duration(seconds: 30),
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      connectTimeout: defaultTimeout,
      receiveTimeout: defaultTimeout,
      sendTimeout: defaultTimeout,
    );

    // 僅在 debug / profile 模式安裝 log 攔截器：透過 assert 副作用判斷
    // 模式，避免依賴 `package:flutter/foundation.dart`，讓網路層保持純 Dart。
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    if (debug) {
      _dio.interceptors.add(_LogInterceptor());
    }
  }

  final Dio _dio;

  @override
  Future<T> execute<T>(ApiRequest<T> request) async {
    try {
      final response = await _sendRequest(request);
      return request.parseResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
    // 注意：parseResponse 內若拋 FormatException / TypeError 不在此攔截，
    // 讓呼叫端（Repository）能精準翻譯為 MalformedForecastDataError；
    // 若統一包成 ApiException(無 statusCode) 會被誤判為網路錯誤。
  }

  Future<Response<dynamic>> _sendRequest(ApiRequest<dynamic> request) {
    final options = Options(
      method: request.method.value,
      headers: request.headers,
      receiveTimeout: request.timeout ?? _dio.options.receiveTimeout,
      sendTimeout: request.timeout ?? _dio.options.sendTimeout,
    );

    return _dio.request(
      request.fullUrl,
      queryParameters: request.queryParameters,
      data: request.body,
      options: options,
    );
  }

  ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          '請求超時',
          statusCode: 408,
          stackTrace: e.stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return ApiException(
          _getErrorMessage(statusCode, e.response?.data),
          statusCode: statusCode,
          response: e.response?.data,
          stackTrace: e.stackTrace,
        );

      case DioExceptionType.cancel:
        return ApiException('請求已取消', stackTrace: e.stackTrace);

      case DioExceptionType.connectionError:
        return ApiException('網路連線失敗，請檢查網路設定', stackTrace: e.stackTrace);

      case DioExceptionType.badCertificate:
        return ApiException('SSL 憑證驗證失敗', stackTrace: e.stackTrace);

      case DioExceptionType.unknown:
        return ApiException(
          '未知錯誤: ${e.message}',
          stackTrace: e.stackTrace,
        );
    }
  }

  String _getErrorMessage(int? statusCode, dynamic responseData) {
    if (responseData != null) {
      try {
        if (responseData is Map) {
          final message = responseData['message'] ?? responseData['error'];
          if (message != null) return message.toString();
        }
      } catch (_) {
        // 忽略解析錯誤
      }
    }

    switch (statusCode) {
      case 400:
        return '請求參數錯誤';
      case 401:
        return '未授權，請重新登入';
      case 403:
        return '無權限存取';
      case 404:
        return '資源不存在';
      case 408:
        return '請求超時';
      case 429:
        return '請求次數過多，請稍後再試';
      case 500:
        return '伺服器內部錯誤';
      case 502:
        return '伺服器網關錯誤';
      case 503:
        return '服務暫時無法使用';
      default:
        return '請求失敗 ($statusCode)';
    }
  }

  /// 關閉底層 HTTP 客戶端（測試 / 應用結束時呼叫）。
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Log.d('╔══════════════════════════════════════════════════════════════');
    Log.d('║ ${options.method}: ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      Log.d('║ Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      Log.d('║ Body: ${options.data}');
    }
    if (options.headers.isNotEmpty) {
      Log.d('║ Headers: ${options.headers}');
    }
    Log.d('╚══════════════════════════════════════════════════════════════');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Log.d(
      '✓ Response: ${response.statusCode} - ${response.requestOptions.uri}',
    );
    Log.d('  Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.e('DioHttpService: Error - ${err.type} - ${err.requestOptions.uri}', err);
    Log.d('  Message: ${err.message}');
    if (err.response != null) {
      Log.d('  Status: ${err.response?.statusCode}');
      Log.d('  Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}
