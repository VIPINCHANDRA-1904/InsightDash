import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://insightdash-1.onrender.com/api";

  Future<List<dynamic>> getFiles() async {
    final response = await http.get(Uri.parse('$baseUrl/upload/files/'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('Failed to load files');
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String fileName, List<int>? bytes) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/upload/'));
    
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
      throw Exception('Failed to upload file');
    }
  }

  Future<Map<String, dynamic>> getAnalyticsSummary(int fileId) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/$fileId/summary'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load analytics: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getChartData(int fileId, String column, {String chartType = 'bar'}) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/$fileId/chart?column=$column&chart_type=$chartType'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load chart data');
    }
  }
}
