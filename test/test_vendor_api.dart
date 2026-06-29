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
  if (token == null) {
    print('Failed to get token');
    return;
  }

  print('\n--- Fetching Vendor List ---');
  final listResponse = await http.get(
    Uri.parse('$baseUrl/panel-fetch-vendor-list'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  print('List Status: ${listResponse.statusCode}');
  
  if (listResponse.statusCode == 200) {
    final listData = jsonDecode(listResponse.body);
    if (listData['vendor'] != null) {
      final vendors = listData['vendor'] as List;
      print('Total vendors: ${vendors.length}');
      if (vendors.isNotEmpty) {
        print('First vendor raw: ${jsonEncode(vendors.first)}');
      }
    } else {
      print('List body: ${listResponse.body}');
    }
  } else {
    print('Failed to fetch list: ${listResponse.body}');
  }

  // Let's test fetch by ID if possible
  print('\n--- Fetching Vendor Detail (checking standard endpoint formats) ---');
  final detailResponse1 = await http.get(
    Uri.parse('$baseUrl/panel-fetch-vendor-by-id/11'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  print('Detail 11 Status: ${detailResponse1.statusCode}');
  print('Detail 11 Body: ${detailResponse1.body}');
  
  final detailResponse2 = await http.get(
    Uri.parse('$baseUrl/panel-fetch-vendor/11'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  print('Detail /panel-fetch-vendor/11 Status: ${detailResponse2.statusCode}');
  print('Detail /panel-fetch-vendor/11 Body: ${detailResponse2.body}');
}
