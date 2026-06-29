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
  final String name = 'Gemini Multipart Test $randomNum';

  print('--- Testing Multipart Request ---');
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/panel-create-vendor'),
  );
  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  request.fields['vendor_name'] = name;
  request.fields['vendor_mobile'] = '98765${randomNum.toString().padLeft(5, '0')}';
  request.fields['vendor_email'] = 'gemini_multi_$randomNum@test.com';
  request.fields['vendor_address'] = 'Multipart Address $randomNum';
  request.fields['vendor_city'] = 'City $randomNum';
  request.fields['vendor_category'] = 'Coconut Oil';
  request.fields['vendor_trader'] = '1'; // trader 1 works for admins
  request.fields['vendor_status'] = 'Active';

  // Nesting form fields inside MultipartRequest fields
  request.fields['vendorProduct_sub_data[0][vendor_product_category]'] = 'Coconut Oil';
  request.fields['vendorProduct_sub_data[0][vendor_product_category_sub]'] = 'demo';
  request.fields['vendorProduct_sub_data[0][vendor_product]'] = 'Multipart Product';
  request.fields['vendorProduct_sub_data[0][vendor_product_size]'] = '10 Litres';
  request.fields['vendorProduct_sub_data[0][vendor_product_rate]'] = '50';
  request.fields['vendorProduct_sub_data[0][vendor_trader]'] = '1';
  request.fields['vendorProduct_sub_data[0][vendor_product_status]'] = 'Active';

  var response = await request.send();
  var responseBody = await response.stream.bytesToString();
  print('Create Status: ${response.statusCode} Body: $responseBody');

  if (response.statusCode == 200) {
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
