import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estate.dart';
import '../models/user_profile.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const _baseUrl = 'http://192.168.10.231:8000/api/v1';

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  dynamic _handle(http.Response response) {
    final json = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    final detail =
        (json is Map ? json['detail'] : null) as String? ?? 'An error occurred';
    throw ApiException(response.statusCode, detail);
  }

  Future<dynamic> _get(String path, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
    );
    return _handle(response);
  }

  Future<dynamic> _post(
    String path,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<UserProfile> getMe(String token) async {
    final json = await _get('/users/me', token);
    return UserProfile.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<Estate>> listEstates(String token) async {
    final json = await _get('/estates/', token);
    return (json['data'] as List)
        .map((e) => Estate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Estate> createEstate(
    String token, {
    required String name,
    required String location,
  }) async {
    final json = await _post('/estates/', token, {
      'name': name,
      'location': location,
    });
    return Estate.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<UserProfile>> listSupervisors(
      String token, String estateId) async {
    final json = await _get('/users/estate/$estateId', token);
    return (json['data'] as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> createSupervisor(
    String token, {
    required String name,
    required String email,
    required String password,
    required String estateId,
  }) async {
    final json = await _post('/users/', token, {
      'name': name,
      'email': email,
      'password': password,
      'estateId': estateId,
      'role': 'supervisor',
    });
    return UserProfile.fromJson(json['data'] as Map<String, dynamic>);
  }
}
