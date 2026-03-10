import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://insightdash-production.up.railway.app/api";
  
  static String? _token;

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    await _loadToken();
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _token = result['data']['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      return result;
    } else {
      throw Exception(result['detail'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return result;
    } else {
      throw Exception(result['detail'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }

  Future<List<dynamic>> getFiles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/upload/files/'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('Failed to load files: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String fileName, List<int>? bytes) async {
    await _loadToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/upload/'));
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    if (bytes != null && (kIsWeb || filePath.isEmpty)) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload file: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAnalyticsSummary(int fileId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/$fileId/summary'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load analytics: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getChartData(int fileId, String column, {String chartType = 'bar'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/$fileId/chart?column=$column&chart_type=$chartType'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load chart data');
    }
  }
}
