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

  // Define patterns to test:
  final List<Map<String, dynamic>> patterns = [
    {
      'name': 'CamelCase vendorProduct_sub_data nested form fields with trader 1',
      'body': {
        'vendor_trader': '1',
        'vendorProduct_sub_data[0][vendor_product_category]': 'Coconut Oil',
        'vendorProduct_sub_data[0][vendor_product_category_sub]': 'demo',
        'vendorProduct_sub_data[0][vendor_product]': 'Product Camel trader 1',
        'vendorProduct_sub_data[0][vendor_product_size]': '10',
        'vendorProduct_sub_data[0][vendor_product_rate]': '100',
        'vendorProduct_sub_data[0][vendor_trader]': '1',
        'vendorProduct_sub_data[0][vendor_product_status]': 'Active',
      }
    },
    {
      'name': 'SnakeCase vendor_product_sub_data nested form fields with trader 1',
      'body': {
        'vendor_trader': '1',
        'vendor_product_sub_data[0][vendor_product_category]': 'Coconut Oil',
        'vendor_product_sub_data[0][vendor_product_category_sub]': 'demo',
        'vendor_product_sub_data[0][vendor_product]': 'Product Snake trader 1',
        'vendor_product_sub_data[0][vendor_product_size]': '10',
        'vendor_product_sub_data[0][vendor_product_rate]': '100',
        'vendor_product_sub_data[0][vendor_trader]': '1',
        'vendor_product_sub_data[0][vendor_product_status]': 'Active',
      }
    },
    {
      'name': 'CamelCase vendorProduct_sub_data as JSON string with trader 1',
      'body': {
        'vendor_trader': '1',
        'vendorProduct_sub_data': jsonEncode([
          {
            'vendor_product_category': 'Coconut Oil',
            'vendor_product_category_sub': 'demo',
            'vendor_product': 'Product JSON Camel trader 1',
            'vendor_product_size': '10',
            'vendor_product_rate': '100',
            'vendor_trader': '1',
            'vendor_product_status': 'Active',
          }
        ])
      }
    },
    {
      'name': 'SnakeCase vendor_product_sub_data as JSON string with trader 1',
      'body': {
        'vendor_trader': '1',
        'vendor_product_sub_data': jsonEncode([
          {
            'vendor_product_category': 'Coconut Oil',
            'vendor_product_category_sub': 'demo',
            'vendor_product': 'Product JSON Snake trader 1',
            'vendor_product_size': '10',
            'vendor_product_rate': '100',
            'vendor_trader': '1',
            'vendor_product_status': 'Active',
          }
        ])
      }
    }
  ];

  for (var pattern in patterns) {
    final String label = pattern['name'];
    final Map<String, dynamic> extraParams = pattern['body'];
    
    final randomNum = DateTime.now().millisecondsSinceEpoch % 100000;
    final String name = 'Gemini Final $randomNum';

    final Map<String, String> bodyParams = {
      'vendor_name': name,
      'vendor_mobile': '98765${randomNum.toString().padLeft(5, '0')}',
      'vendor_email': 'gemini_final_$randomNum@test.com',
      'vendor_address': 'Test Address $randomNum',
      'vendor_city': 'City $randomNum',
      'vendor_category': 'Coconut Oil',
      'vendor_status': 'Active',
    };
    
    // Add extra params
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
      // Find the vendor in list
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
      } else {
        print('$label: Response ok, but vendor not found in list.');
      }
    } else {
      print('$label: FAILED with status ${res.statusCode}. Body: ${res.body}');
    }
  }
}
