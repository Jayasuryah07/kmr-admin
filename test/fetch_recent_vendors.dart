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
    print('Failed to login');
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

  if (listResponse.statusCode != 200) {
    print('Failed to fetch vendor list: ${listResponse.body}');
    return;
  }

  final listData = jsonDecode(listResponse.body);
  final vendors = listData['vendor'] as List;
  
  // Sort vendors by id descending to get the most recent ones first
  vendors.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
  
  print('Total vendors: ${vendors.length}');
  print('Fetching details for the top 15 most recent vendors:');
  
  for (int i = 0; i < 15 && i < vendors.length; i++) {
    final v = vendors[i];
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
      print('Vendor ID $id ($name): status=${v['vendor_status']}, productsCount=${subs.length}');
      if (subs.isNotEmpty) {
        print('  Sub-products: ${jsonEncode(subs)}');
      }
    } else {
      print('Failed to fetch details for vendor $id ($name)');
    }
  }
}
