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

  print('\n--- Fetching All Vendor Details ---');
  final listResponse = await http.get(
    Uri.parse('$baseUrl/panel-fetch-vendor-list'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (listResponse.statusCode != 200) {
    print('Failed to fetch vendor list');
    return;
  }

  final listData = jsonDecode(listResponse.body);
  final vendors = listData['vendor'] as List;
  print('Total vendors to inspect: ${vendors.length}');

  int vendorsWithProducts = 0;
  for (var v in vendors) {
    final int id = v['id'];
    final name = v['vendor_name'];
    final detailResponse = await http.get(
      Uri.parse('$baseUrl/panel-fetch-vendor-by-id/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (detailResponse.statusCode == 200) {
      final detailData = jsonDecode(detailResponse.body);
      final subs = detailData['vendorSub'] as List;
      if (subs.isNotEmpty) {
        vendorsWithProducts++;
        print('Vendor ID $id ($name) has ${subs.length} sub-products:');
        print('Raw Detail: ${detailResponse.body}');
        if (vendorsWithProducts >= 5) {
          print('Stopping after showing 5 vendors with products');
          break;
        }
      }
    }
  }
  print('Done inspecting.');
}
