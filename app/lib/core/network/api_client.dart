import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'token_manager.dart';

/// Exception khusus untuk kesalahan respon dari Backend SIGAP.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.errors,
  });

  /// Mengambil pesan error pertama bila ada dictionary `errors`
  String get firstErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstVal = errors!.values.first;
      if (firstVal is List && firstVal.isNotEmpty) {
        return firstVal.first.toString();
      }
      return firstVal.toString();
    }
    return message;
  }

  @override
  String toString() => message;
}

/// HTTP Client terpadu untuk berkomunikasi dengan Django REST API.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 15);

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';

    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse(fullUrl);
    }
    final normalized = queryParams.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse(fullUrl).replace(queryParameters: normalized);
  }

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic>) {
        // Jika format amplop DRF SIGAP {status: "success", data: ...}
        if (jsonBody.containsKey('data')) {
          return jsonBody['data'];
        }
        // Jika format paginasi {status: "success", results: [...], count: 10}
        if (jsonBody.containsKey('results')) {
          return jsonBody;
        }
        return jsonBody;
      }
      return jsonBody;
    }

    // Penanganan error response
    String code = 'UNKNOWN_ERROR';
    String message = 'Terjadi kesalahan pada server (${response.statusCode}).';
    Map<String, dynamic>? errors;

    if (jsonBody is Map<String, dynamic>) {
      code = jsonBody['code']?.toString() ?? code;
      message = jsonBody['message']?.toString() ?? message;
      if (jsonBody['errors'] is Map<String, dynamic>) {
        errors = jsonBody['errors'] as Map<String, dynamic>;
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
      errors: errors,
    );
  }

  Future<T> _wrapNetworkCall<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'Koneksi ke server timeout. Silakan periksa jaringan Anda.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        code: 'CONNECTION_REFUSED',
        message: 'Tidak dapat terhubung ke server backend di ${ApiConfig.baseUrl}. Pastikan server Django sudah berjalan.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Gagal menghubungi server: $e',
      );
    }
  }

  /// Request GET
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _wrapNetworkCall(() async {
      final uri = _buildUri(path, queryParams);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.get(uri, headers: headers);
      return _processResponse(response);
    });
  }

  /// Request POST
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _wrapNetworkCall(() async {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  /// Request PATCH
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _wrapNetworkCall(() async {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  /// Request DELETE
  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    return _wrapNetworkCall(() async {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.delete(uri, headers: headers);
      return _processResponse(response);
    });
  }
}

