import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krm_admin/models/vendor_user_model.dart';
import 'package:krm_admin/services/auth_service.dart';

class VendorUserService {
  static const String baseUrl = 'https://kmrlive.in/public/api';
  final AuthService _authService = AuthService();

  // Fetch all vendor users
  Future<List<VendorUserModel>> fetchVendorUsers() async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-user-list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendor Users Response: ${response.statusCode}');
      print('Fetch Vendor Users Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['adminUser'] != null) {
          List<dynamic> usersJson = data['adminUser'];
          List<VendorUserModel> users = [];
          for (var json in usersJson) {
            users.add(VendorUserModel.fromJson(json));
          }
          print('Found ${users.length} vendor users');
          return users;
        } else if (data['data'] != null) {
          if (data['data'] is List) {
            List<dynamic> usersJson = data['data'] as List;
            List<VendorUserModel> users = [];
            for (var json in usersJson) {
              users.add(VendorUserModel.fromJson(json));
            }
            return users;
          }
          return [];
        } else {
          return [];
        }
      } else {
        print('Failed to fetch vendor users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching vendor users: $e');
      return [];
    }
  }

  // Fetch vendor user by ID
  Future<VendorUserModel?> fetchVendorUserById(int id) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-user-by-id/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendor User By ID Response: ${response.statusCode}');
      print('Fetch Vendor User By ID Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Handle different response formats
        if (data['adminUser'] != null) {
          return VendorUserModel.fromJson(data['adminUser']);
        } else if (data['data'] != null) {
          if (data['data'] is Map<String, dynamic>) {
            return VendorUserModel.fromJson(data['data']);
          }
          return null;
        } else if (data['id'] != null) {
          // Direct user data
          return VendorUserModel.fromJson(data);
        } else {
          return null;
        }
      } else {
        print('Failed to fetch vendor user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching vendor user by ID: $e');
      return null;
    }
  }

  // Create new vendor user
  Future<Map<String, dynamic>> createVendorUser({
    required String name,
    required String mobile,
    required String email,
    required String remarks,
  }) async {
    try {
      String? token = await _authService.getToken();
      
      final requestBody = {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'email': email.trim(),
        'remarks': remarks.trim(),
      };

      print('Create Vendor User Request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/panel-create-vendor-user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Create Vendor User Response: ${response.statusCode}');
      print('Create Vendor User Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor user created successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create vendor user. Please try again.',
        };
      }
    } catch (e) {
      print('Error creating vendor user: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update vendor user
  Future<Map<String, dynamic>> updateVendorUser({
    required int id,
    required String name,
    required String mobile,
    required String email,
    required String remarks,
    required String status,
  }) async {
    try {
      String? token = await _authService.getToken();
      
      final requestBody = {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'email': email.trim(),
        'remarks': remarks.trim(),
        'status': status,
      };

      print('Update Vendor User Request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/panel-update-vendor-user/$id?_method=PUT'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Update Vendor User Response: ${response.statusCode}');
      print('Update Vendor User Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor user updated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vendor user. Please try again.',
        };
      }
    } catch (e) {
      print('Error updating vendor user: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}