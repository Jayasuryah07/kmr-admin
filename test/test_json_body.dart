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

  final randomNum = DateTime.now().millisecondsSinceEpoch % 100000;
  final String name = 'Gemini JSON Body Test $randomNum';

  print('--- Testing JSON request body ---');
  final Map<String, dynamic> payload = {
    'vendor_name': name,
    'vendor_mobile': '98765${randomNum.toString().padLeft(5, '0')}',
    'vendor_email': 'gemini_json_$randomNum@test.com',
    'vendor_address': 'JSON Address $randomNum',
    'vendor_city': 'City $randomNum',
    'vendor_category': 'Coconut Oil',
    'vendor_trader': '1', // admins ID
    'vendor_status': 'Active',
    'vendorProduct_sub_data': [
      {
        'vendor_product_category': 'Coconut Oil',
        'vendor_product_category_sub': 'demo',
        'vendor_product': 'JSON Subproduct',
        'vendor_product_size': '10 Litres',
        'vendor_product_rate': 50,
        'vendor_trader': '1',
        'vendor_product_status': 'Active',
      }
    ]
  };

  final res = await http.post(
    Uri.parse('$baseUrl/panel-create-vendor'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );
  
  print('Create Status: ${res.statusCode} Body: ${res.body}');

  if (res.statusCode == 200) {
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
      print('Created vendor ID: $id');
      
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
        print('SUCCESS! Subs: ${jsonEncode(subs)}');
      } else {
        print('Failed to attach sub products. Response: ${detailResponse.body}');
      }
    }
  }
}
