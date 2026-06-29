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

  // 1. Fetch Categories
  print('\n--- Categories ---');
  final catRes = await http.get(
    Uri.parse('$baseUrl/panel-fetch-category'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (catRes.statusCode == 200) {
    final data = jsonDecode(catRes.body);
    final categories = data['category'] as List;
    for (var c in categories) {
      print('Category ID: ${c['id']}, Name: ${c['category_name']}');
    }
  }

  // 2. Fetch Subcategories
  print('\n--- Subcategories ---');
  final subRes = await http.get(
    Uri.parse('$baseUrl/panel-fetch-sub-category-list'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (subRes.statusCode == 200) {
    final data = jsonDecode(subRes.body);
    final subcategories = data['categorySub'] as List;
    print('Total subcategories: ${subcategories.length}');
    for (var s in subcategories.take(15)) {
      print('Subcategory ID: ${s['id']}, Name: ${s['category_sub_name']}, Category: ${s['category_name']}');
    }
  }
}
