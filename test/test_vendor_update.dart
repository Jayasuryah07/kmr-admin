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

  const int testVendorId = 94;

  // Pattern A: sub_category, product_name, size, rate
  await testUpdatePattern(baseUrl, token, testVendorId, 'Pattern A', {
    'sub_category[0]': 'Coconut',
    'product_name[0]': 'PALM OIL PATTERN A',
    'size[0]': '10Kg',
    'rate[0]': '1001',
  });

  // Pattern C: category_sub, product, size, rate
  await testUpdatePattern(baseUrl, token, testVendorId, 'Pattern C', {
    'category_sub[0]': 'Copra',
    'product[0]': 'PALM OIL PATTERN C',
    'size[0]': '15Kg',
    'rate[0]': '1003',
  });

  // Pattern D: category_sub_name, product_name, size, rate
  await testUpdatePattern(baseUrl, token, testVendorId, 'Pattern D', {
    'category_sub_name[0]': 'Coconut',
    'product_name[0]': 'PALM OIL PATTERN D',
    'size[0]': '20Kg',
    'rate[0]': '1004',
  });

  // Pattern E: JSON strings of arrays
  await testUpdatePattern(baseUrl, token, testVendorId, 'Pattern E', {
    'vendor_product_category_sub': jsonEncode(['Coconut']),
    'vendor_product': jsonEncode(['PALM OIL PATTERN E']),
    'vendor_product_size': jsonEncode(['25Kg']),
    'vendor_product_rate': jsonEncode(['1005']),
  });

  // Pattern F: Single JSON array of objects
  await testUpdatePattern(baseUrl, token, testVendorId, 'Pattern F', {
    'products': jsonEncode([{
      'category_sub': 'Coconut',
      'product': 'PALM OIL PATTERN F',
      'size': '30Kg',
      'rate': 1006
    }]),
    'vendorSub': jsonEncode([{
      'vendor_product_category_sub': 'Coconut',
      'vendor_product': 'PALM OIL PATTERN F2',
      'vendor_product_size': '30Kg',
      'vendor_product_rate': 1007
    }])
  });
}

Future<void> testUpdatePattern(String baseUrl, String token, int id, String label, Map<String, String> extraParams) async {
  print('\n--- Testing Update with $label ---');
  
  final Map<String, String> params = {
    'vendor_name': 'Gemini Probe Vendor 39190',
    'vendor_mobile': '9003879810',
    'vendor_email': 'geminiprobe_39190@test.com',
    'vendor_address': 'Probe Address',
    'vendor_city': 'Bengaluru',
    'vendor_category': 'Coconut Oil',
    'vendor_trader': '3',
    'vendor_status': 'Active',
  };
  params.addAll(extraParams);

  final updateResponse = await http.post(
    Uri.parse('$baseUrl/panel-update-vendor/$id?_method=PUT'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: params,
  );

  print('Update Status for $label: ${updateResponse.statusCode}');
  
  if (updateResponse.statusCode == 200) {
    final detailResponse = await http.get(
      Uri.parse('$baseUrl/panel-fetch-vendor-by-id/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final detailData = jsonDecode(detailResponse.body);
    final subs = detailData['vendorSub'] as List;
    print('Subs Count: ${subs.length}');
    if (subs.isNotEmpty) {
      print('Succeeded! Subs: ${jsonEncode(subs)}');
    }
  } else {
    print('Failed update: ${updateResponse.body}');
  }
}
