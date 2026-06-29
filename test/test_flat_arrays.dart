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

  // Define patterns:
  final List<Map<String, dynamic>> patterns = [
    {
      'name': 'Pattern 8: Flat arrays without indices like vendor_product[]',
      'body': {
        'vendor_trader': '15',
        'vendor_product[]': 'Product P8',
        'vendor_product_category_sub[]': 'demo',
        'vendor_product_size[]': '10',
        'vendor_product_rate[]': '100',
        'vendor_product_status[]': 'Active',
        'vendor_product_category[]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 9: Flat arrays with indices like vendor_product[0]',
      'body': {
        'vendor_trader': '15',
        'vendor_product[0]': 'Product P9',
        'vendor_product_category_sub[0]': 'demo',
        'vendor_product_size[0]': '10',
        'vendor_product_rate[0]': '100',
        'vendor_product_status[0]': 'Active',
        'vendor_product_category[0]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 10: Simple names flat arrays with indices like product[0]',
      'body': {
        'vendor_trader': '15',
        'product[0]': 'Product P10',
        'sub_category[0]': 'demo',
        'size[0]': '10',
        'rate[0]': '100',
        'status[0]': 'Active',
        'category[0]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 11: Simple names flat arrays without indices like product[]',
      'body': {
        'vendor_trader': '15',
        'product[]': 'Product P11',
        'sub_category[]': 'demo',
        'size[]': '10',
        'rate[]': '100',
        'status[]': 'Active',
        'category[]': 'Coconut Oil',
      }
    }
  ];

  for (var pattern in patterns) {
    final String label = pattern['name'];
    final Map<String, dynamic> extraParams = pattern['body'];
    
    final randomNum = DateTime.now().millisecondsSinceEpoch % 100000;
    final String name = 'Gemini Flat $randomNum';

    final Map<String, String> bodyParams = {
      'vendor_name': name,
      'vendor_mobile': '98765${randomNum.toString().padLeft(5, '0')}',
      'vendor_email': 'gemini_flat_$randomNum@test.com',
      'vendor_address': 'Flat Address $randomNum',
      'vendor_city': 'City $randomNum',
      'vendor_category': 'Coconut Oil',
      'vendor_status': 'Active',
    };
    
    extraParams.forEach((k, v) {
      bodyParams[k] = v.toString();
    });

    final res = await http.post(
      Uri.parse('$baseUrl/panel-create-vendor'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: bodyParams,
    );

    if (res.statusCode == 200) {
      // Find the vendor
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
        print('$label: SUCCESS! Created ID: $id, Subs count: ${subs.length}');
        if (subs.isNotEmpty) {
          print('  Sub-product content: ${jsonEncode(subs)}');
        }
      }
    } else {
      print('$label: FAILED with status ${res.statusCode}. Body: ${res.body}');
    }
  }
}
