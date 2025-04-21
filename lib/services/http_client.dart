import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class HttpClient {
  // Singleton pattern
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;

  HttpClient._internal();

  // Default timeout for requests
  final Duration _timeout = const Duration(seconds: 5);

  // Get request with timeout
  Future<Map<String, dynamic>?> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      print('Request timeout: $url');
      return null;
    } catch (e) {
      print('HTTP request error: $e');
      return null;
    }
  }

  // Post request with timeout
  Future<Map<String, dynamic>?> post(
      String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      print('Request timeout: $url');
      return null;
    } catch (e) {
      print('HTTP request error: $e');
      return null;
    }
  }
}
