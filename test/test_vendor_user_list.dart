import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String baseUrl = 'https://kmrlive.in/public/api';
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

  final res = await http.get(
    Uri.parse('$baseUrl/panel-fetch-vendor-user-list'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    final users = body['adminUser'] as List;
    print('Total users: ${users.length}');
    for (int i = 0; i < 15 && i < users.length; i++) {
      print('User $i: ${jsonEncode(users[i])}');
    }
  }
}
