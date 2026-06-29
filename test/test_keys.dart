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

  // Define the patterns we want to test
  final List<Map<String, dynamic>> patterns = [
    {
      'name': 'Pattern 1: Nesting with vendorProduct_sub_data[0][...]',
      'body': {
        'vendorProduct_sub_data[0][vendor_product]': 'Product P1',
        'vendorProduct_sub_data[0][vendor_product_category_sub]': 'demo',
        'vendorProduct_sub_data[0][vendor_product_size]': '10',
        'vendorProduct_sub_data[0][vendor_product_rate]': '100',
        'vendorProduct_sub_data[0][vendor_trader]': '3',
        'vendorProduct_sub_data[0][vendor_product_status]': 'Active',
        'vendorProduct_sub_data[0][vendor_product_category]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 2: vendorProduct_sub_data as a JSON string of objects',
      'body': {
        'vendorProduct_sub_data': jsonEncode([
          {
            'vendor_product': 'Product P2',
            'vendor_product_category_sub': 'demo',
            'vendor_product_size': '10',
            'vendor_product_rate': '100',
            'vendor_trader': '3',
            'vendor_product_status': 'Active',
            'vendor_product_category': 'Coconut Oil'
          }
        ])
      }
    },
    {
      'name': 'Pattern 3: Flat arrays like vendor_product[0], vendor_product_category_sub[0]',
      'body': {
        'vendor_product[0]': 'Product P3',
        'vendor_product_category_sub[0]': 'demo',
        'vendor_product_size[0]': '10',
        'vendor_product_rate[0]': '100',
        'vendor_trader[0]': '3',
        'vendor_product_status[0]': 'Active',
        'vendor_product_category[0]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 4: Flat arrays without index like vendor_product[], vendor_product_category_sub[]',
      'body': {
        'vendor_product[]': 'Product P4',
        'vendor_product_category_sub[]': 'demo',
        'vendor_product_size[]': '10',
        'vendor_product_rate[]': '100',
        'vendor_trader[]': '3',
        'vendor_product_status[]': 'Active',
        'vendor_product_category[]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 5: JSON-encoded lists under separate keys',
      'body': {
        'vendor_product': jsonEncode(['Product P5']),
        'vendor_product_category_sub': jsonEncode(['demo']),
        'vendor_product_size': jsonEncode(['10']),
        'vendor_product_rate': jsonEncode(['100']),
        'vendor_trader': jsonEncode(['3']),
        'vendor_product_status': jsonEncode(['Active']),
        'vendor_product_category': jsonEncode(['Coconut Oil']),
      }
    },
    {
      'name': 'Pattern 6: Nesting with simpler keys vendorProduct_sub_data[0][product]',
      'body': {
        'vendorProduct_sub_data[0][product]': 'Product P6',
        'vendorProduct_sub_data[0][category_sub]': 'demo',
        'vendorProduct_sub_data[0][size]': '10',
        'vendorProduct_sub_data[0][rate]': '100',
        'vendorProduct_sub_data[0][trader]': '3',
        'vendorProduct_sub_data[0][status]': 'Active',
        'vendorProduct_sub_data[0][category]': 'Coconut Oil',
      }
    },
    {
      'name': 'Pattern 7: Flat arrays with simplified keys product[0], category_sub[0]',
      'body': {
        'product[0]': 'Product P7',
        'category_sub[0]': 'demo',
        'size[0]': '10',
        'rate[0]': '100',
        'trader[0]': '3',
        'status[0]': 'Active',
        'category[0]': 'Coconut Oil',
      }
    }
  ];

  for (var pattern in patterns) {
    final String label = pattern['name'];
    final Map<String, dynamic> extraParams = pattern['body'];
    
    final randomNum = DateTime.now().millisecondsSinceEpoch % 100000;
    final String name = 'Gemini $randomNum';

    final Map<String, String> bodyParams = {
      'vendor_name': name,
      'vendor_mobile': '98765${randomNum.toString().padLeft(5, '0')}',
      'vendor_email': 'gemini_test_$randomNum@test.com',
      'vendor_address': 'Test Address $randomNum',
      'vendor_city': 'City $randomNum',
      'vendor_category': 'Coconut Oil',
      'vendor_trader': '3',
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
