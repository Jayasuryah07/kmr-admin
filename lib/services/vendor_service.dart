import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krm_admin/models/vendor_model.dart';
import 'package:krm_admin/models/vendor_live_model.dart';
import 'package:krm_admin/models/vendor_spot_rate_model.dart';
import 'package:krm_admin/services/auth_service.dart';

class VendorService {
  static const String baseUrl = 'https://kmrlive.in/public/api';
  final AuthService _authService = AuthService();

  // Fetch all vendors
  Future<List<VendorModel>> fetchVendors() async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendors Response: ${response.statusCode}');
      print('Fetch Vendors Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['vendor'] != null) {
          List<dynamic> vendorsJson = data['vendor'];
          List<VendorModel> vendors = [];
          for (var json in vendorsJson) {
            vendors.add(VendorModel.fromJson(json));
          }
          return vendors;
        } else if (data['data'] != null) {
          if (data['data'] is List) {
            List<dynamic> vendorsJson = data['data'] as List;
            List<VendorModel> vendors = [];
            for (var json in vendorsJson) {
              vendors.add(VendorModel.fromJson(json));
            }
            return vendors;
          }
          return [];
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching vendors: $e');
      return [];
    }
  }

  // Create new vendor
  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> vendorData) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/panel-create-vendor'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vendorData),
      );

      print('Create Vendor Response: ${response.statusCode}');
      print('Create Vendor Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor created successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create vendor. Please try again.',
        };
      }
    } catch (e) {
      print('Error creating vendor: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch vendor by id
  Future<Map<String, dynamic>?> fetchVendorById(int id) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-by-id/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching vendor by id: $e');
      return null;
    }
  }

  // Update vendor
  Future<Map<String, dynamic>> updateVendor(int id, Map<String, dynamic> vendorData) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/panel-update-vendor/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(vendorData),
      );

      print('Update Vendor Response: ${response.statusCode}');
      print('Update Vendor Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor updated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vendor. Please try again.',
        };
      }
    } catch (e) {
      print('Error updating vendor: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch all live vendors products
  Future<List<VendorLiveModel>> fetchVendorLiveList() async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-live-list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendor Live List Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['vendor'] != null) {
          List<dynamic> liveJson = data['vendor'];
          List<VendorLiveModel> liveList = [];
          for (var json in liveJson) {
            liveList.add(VendorLiveModel.fromJson(json));
          }
          return liveList;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vendor live list: $e');
      return [];
    }
  }

  // Fetch vendor live by id
  Future<VendorLiveModel?> fetchVendorLiveById(int id) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-live-by-id/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendor Live By ID Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['vendor'] != null) {
          return VendorLiveModel.fromJson(data['vendor']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching vendor live by id: $e');
      return null;
    }
  }

  // Update vendor live rate/status
  Future<Map<String, dynamic>> updateVendorLive(int id, Map<String, dynamic> liveData) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/panel-update-vendor-live/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(liveData),
      );

      print('Update Vendor Live Response: ${response.statusCode}');
      print('Update Vendor Live Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor live details updated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vendor live. Please try again.',
        };
      }
    } catch (e) {
      print('Error updating vendor live: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch all spot rates
  Future<List<VendorSpotRateModel>> fetchVendorSpotRatesList() async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor-spot-rates-list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Vendor Spot Rates List Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['vendor'] != null) {
          List<dynamic> spotJson = data['vendor'];
          List<VendorSpotRateModel> spotList = [];
          for (var json in spotJson) {
            spotList.add(VendorSpotRateModel.fromJson(json));
          }
          return spotList;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vendor spot rates list: $e');
      return [];
    }
  }

  // Fetch eligible vendors for spot rates (trader 3)
  Future<List<Map<String, dynamic>>> fetchSpotEligibleVendors() async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/panel-fetch-vendor/3'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch Spot Eligible Vendors Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['vendor'] != null) {
          return List<Map<String, dynamic>>.from(data['vendor']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching spot eligible vendors: $e');
      return [];
    }
  }

  // Create new vendor spot rate
  Future<Map<String, dynamic>> createVendorSpotRate(Map<String, dynamic> spotData) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/panel-create-vendor-spot-rates'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(spotData),
      );

      print('Create Vendor Spot Rate Response: ${response.statusCode}');
      print('Create Vendor Spot Rate Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor spot rates created successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create vendor spot rates. Please try again.',
        };
      }
    } catch (e) {
      print('Error creating vendor spot rate: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update vendor spot rate
  Future<Map<String, dynamic>> updateVendorSpotRate(int id, Map<String, dynamic> spotData) async {
    try {
      String? token = await _authService.getToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/panel-update-vendor-spot-rates/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(spotData),
      );

      print('Update Vendor Spot Rate Response: ${response.statusCode}');
      print('Update Vendor Spot Rate Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200 || data['status'] == 'success' || data['success'] == true,
          'message': data['msg'] ?? data['message'] ?? 'Vendor spot rates updated successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vendor spot rates. Please try again.',
        };
      }
    } catch (e) {
      print('Error updating vendor spot rate: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}