import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const baseUrl = 'https://kmrlive.in/public/api';
  final login = await http.post(Uri.parse('$baseUrl/panel-login'),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode({'username': 'admins', 'password': '123456', 'device_id': 'test'}),
  );
  final token = jsonDecode(login.body)['UserInfo']?['token'];

  print('--- PUT with all required sub-product fields ---');
  final putRes = await http.put(
    Uri.parse('$baseUrl/panel-update-vendor/151'),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      "vendor_name": "testing",
      "vendor_mobile": "988765432525",
      "vendor_email": "test1342@gmail.com",
      "vendor_address": "fbcf",
      "vendor_city": "testdsxasx",
      "vendor_category": "Dry Fruits",
      "vendor_trader": "1",
      "vendor_no_of_products": 2,
      "vendor_status": "Active",
      "vendorProduct_sub_data": [
        {
          "id": 388,
          "vendor_product_category_sub": "Dates",
          "vendor_product": "Desh",
          "vendor_product_size": "100",
          "vendor_product_rate": "2525",
          "vendor_product_status": "Active",
          "vendor_trader": "1"
        },
        {
          "id": 389,
          "vendor_product_category_sub": "Almond",
          "vendor_product": "ghgyhb",
          "vendor_product_size": "123",
          "vendor_product_rate": "22528",
          "vendor_product_status": "Active",
          "vendor_trader": "1"
        }
      ]
    }),
  );
  print('Status: ${putRes.statusCode}');
  print('Body: ${putRes.body.substring(0, putRes.body.length.clamp(0, 300))}');
}
