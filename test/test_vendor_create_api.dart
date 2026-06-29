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
  final String name = 'Gemini Universal Sub $randomNum';

  print('\n--- Testing Universal Keys inside vendorProduct_sub_data[0] ---');
  
  final String formBody = [
    'vendor_name=${Uri.encodeQueryComponent(name)}',
    'vendor_mobile=9${(randomNum * 99).toString().padLeft(9, '0')}',
    'vendor_email=gemini_univ_$randomNum@test.com',
    'vendor_address=Universal Address',
    'vendor_city=Bengaluru',
    'vendor_category=${Uri.encodeQueryComponent("Coconut Oil")}',
    'vendor_trader=3',
    'vendor_status=Active',
    
    // Sub-product index 0 - ALL possible key variations:
    
    // Category Sub candidates:
    'vendorProduct_sub_data[0][vendor_product_category_sub]=demo',
    'vendorProduct_sub_data[0][category_sub]=demo',
    'vendorProduct_sub_data[0][category_sub_name]=demo',
    'vendorProduct_sub_data[0][sub_category]=demo',
    
    // Product candidates:
    'vendorProduct_sub_data[0][vendor_product]=PALM+OIL+UNIVERSAL',
    'vendorProduct_sub_data[0][product]=PALM+OIL+UNIVERSAL',
    'vendorProduct_sub_data[0][product_name]=PALM+OIL+UNIVERSAL',
    
    // Size candidates:
    'vendorProduct_sub_data[0][vendor_product_size]=10',
    'vendorProduct_sub_data[0][size]=10',
    'vendorProduct_sub_data[0][product_size]=10',
    
    // Rate candidates:
    'vendorProduct_sub_data[0][vendor_product_rate]=1350',
    'vendorProduct_sub_data[0][rate]=1350',
    'vendorProduct_sub_data[0][product_rate]=1350',
    
    // Trader candidates:
    'vendorProduct_sub_data[0][vendor_trader]=3',
    'vendorProduct_sub_data[0][trader]=3',
    
    // Status candidates:
    'vendorProduct_sub_data[0][vendor_product_status]=Active',
    'vendorProduct_sub_data[0][vendor_status]=Active',
    'vendorProduct_sub_data[0][status]=Active',
    
    // Product Category candidates:
    'vendorProduct_sub_data[0][vendor_product_category]=${Uri.encodeQueryComponent("Coconut Oil")}',
    'vendorProduct_sub_data[0][vendor_category]=${Uri.encodeQueryComponent("Coconut Oil")}',
    'vendorProduct_sub_data[0][product_category]=${Uri.encodeQueryComponent("Coconut Oil")}',
    'vendorProduct_sub_data[0][category]=${Uri.encodeQueryComponent("Coconut Oil")}',
  ].join('&');

  final res = await http.post(
    Uri.parse('$baseUrl/panel-create-vendor'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token',
    },
    body: formBody,
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
      }
    }
  }
}
