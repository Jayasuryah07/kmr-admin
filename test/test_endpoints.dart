import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String baseUrl = 'https://kmrlive.in/public/api';
  print('--- Logging in ---');
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/panel-login'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'username': 'admins',
      'password': '123456',
      'device_id': 'krm_test_123456'
    }),
  );

  final loginData = jsonDecode(loginResponse.body);
  final token = loginData['UserInfo']?['token'];
  if (token == null) return;

  final endpoints = [
    '/panel-create-vendor-sub',
    '/panel-create-vendor-product',
    '/panel-create-vendor-rate',
    '/panel-create-vendor-sub-category',
    '/panel-add-vendor-product',
    '/panel-add-vendor-sub',
    '/panel-add-vendor-rate',
  ];

  for (var path in endpoints) {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('POST $path Status: ${res.statusCode}');
    } catch (e) {
      print('Error on POST $path: $e');
    }
  }
}
