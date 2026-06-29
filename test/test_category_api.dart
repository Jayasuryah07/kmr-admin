import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String baseUrl = 'https://kmrlive.in/public/api';
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/panel-login'),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    body: jsonEncode({'username': 'admins', 'password': '123456', 'device_id': 'krm_test_123456'}),
  );

  final token = jsonDecode(loginResponse.body)['UserInfo']?['token'];
  
  final res = await http.get(
    Uri.parse('$baseUrl/panel-fetch-category'),
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  
  final data = jsonDecode(res.body);
  print('Full Category API Response (1 item):');
  print(jsonEncode((data['category'] as List).firstWhere((c) => c['category_name'] == 'Coconut Oil', orElse: () => data['category'][0])));
}
