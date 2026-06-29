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

  final randomNum = DateTime.now().millisecondsSinceEpoch % 100000;
  final String name = 'JSON Sub Test $randomNum';

  print('\n--- Testing JSON Payload ---');
  
  final Map<String, dynamic> payload = {
    "vendor_address": "Universal Address",
    "vendor_category": "Coconut Oil",
    "vendor_city": "Bengaluru",
    "vendor_email": "gemini_json_$randomNum@test.com",
    "vendor_mobile": "9${(randomNum * 99).toString().padLeft(9, '0')}",
    "vendor_name": name,
    "vendor_no_of_products": 2,
    "vendor_trader": "3",
    "vendor_status": "Active",
    "vendorProduct_sub_data": [
      {
        "vendor_product": "SubProd 1",
        "vendor_product_category_sub": "Refined",
        "vendor_product_rate": "100",
        "vendor_product_size": "10"
      },
      {
        "vendor_product": "SubProd 2",
        "vendor_product_category_sub": "Unrefined",
        "vendor_product_rate": "200",
        "vendor_product_size": "20"
      }
    ]
  };

  final res = await http.post(
    Uri.parse('$baseUrl/panel-create-vendor'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );
  print('Status: ${res.statusCode} Body: ${res.body}');
  
  if (res.statusCode == 200) {
    // Search and check details
    final listResponse = await http.get(
      Uri.parse('$baseUrl/panel-fetch-vendor-list'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final listData = jsonDecode(listResponse.body);
    final vendors = listData['vendor'] as List;
    final createdVendor = vendors.firstWhere(
      (v) => v['vendor_name'] == name,
      orElse: () => null,
    );
    if (createdVendor != null) {
      final int id = createdVendor['id'];
      final detailResponse = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-by-id/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final detailData = jsonDecode(detailResponse.body);
      final subs = detailData['vendorSub'] as List;
      print('Subs count: ${subs.length}');
      if (subs.isNotEmpty) {
        print('Succeeded! Subs: ${jsonEncode(subs)}');
      } else {
        print('Failed to save subs. Subs is empty.');
      }
    }
  }
}
