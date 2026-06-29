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
  final String name = 'Gemini ID Test $randomNum';

  print('--- Testing with Category/Subcategory IDs ---');
  final Map<String, String> bodyParams = {
    'vendor_name': name,
    'vendor_mobile': '98765${randomNum.toString().padLeft(5, '0')}',
    'vendor_email': 'gemini_id_$randomNum@test.com',
    'vendor_address': 'Address $randomNum',
    'vendor_city': 'City $randomNum',
    'vendor_category': '6', // Category ID for Coconut Oil
    'vendor_trader': '15',
    'vendor_status': 'Active',
    
    // Sub-product index 0:
    'vendorProduct_sub_data[0][vendor_product_category]': '6', // Category ID
    'vendorProduct_sub_data[0][vendor_product_category_sub]': '56', // Subcategory ID for demo
    'vendorProduct_sub_data[0][vendor_product]': 'ID Product $randomNum',
    'vendorProduct_sub_data[0][vendor_product_size]': '10',
    'vendorProduct_sub_data[0][vendor_product_rate]': '500',
    'vendorProduct_sub_data[0][vendor_trader]': '15',
    'vendorProduct_sub_data[0][vendor_product_status]': 'Active',
  };

  final res = await http.post(
    Uri.parse('$baseUrl/panel-create-vendor'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: bodyParams,
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
