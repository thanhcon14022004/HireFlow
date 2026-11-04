import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException(this.message, {this.code = 'ERROR', this.statusCode = 400});

  @override
  String toString() => message;
}

class ApiService {
  static const String tokenKey = 'hireflow_jwt_token';
  static const String userKey = 'hireflow_user_data';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Đã xảy ra lỗi (${response.statusCode})';
    String code = 'API_ERROR';

    if (body is Map<String, dynamic>) {
      if (body['message'] != null) {
        message = body['message'].toString();
      }
      if (body['code'] != null) {
        code = body['code'].toString();
      }
    }

    throw ApiException(message, code: code, statusCode: response.statusCode);
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API GET Error: $e');
      throw ApiException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    }
  }

  static Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API POST Error: $e');
      throw ApiException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.');
    }
  }

  static Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API PUT Error: $e');
      throw ApiException('Không thể kết nối đến máy chủ.');
    }
  }

  static Future<dynamic> patch(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API PATCH Error: $e');
      throw ApiException('Không thể kết nối đến máy chủ.');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API DELETE Error: $e');
      throw ApiException('Không thể kết nối đến máy chủ.');
    }
  }

  static Future<dynamic> uploadFile(String endpoint, List<int> bytes, String filename, {Map<String, String>? fields}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Upload Error: $e');
      throw ApiException('Tải lên tệp không thành công: ${e.toString()}');
    }
  }

  static Future<Uint8List> getBytes(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException('Tải tệp tin thất bại (${response.statusCode})', statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('API GET BYTES Error: $e');
      throw ApiException('Không thể tải tệp tin từ máy chủ.');
    }
  }
}

