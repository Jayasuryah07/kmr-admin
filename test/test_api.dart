import 'dart:convert';
import 'package:http/http.dart' as http;

/// Vendor model that safely parses fields returned by the API list endpoint
class VendorModel {
  final int id;
  final String vendorName;
  final String vendorMobile;
  final String vendorCategory;
  final String vendorTrader;
  final int vendorNoOfProducts;
  final String vendorStatus;

  VendorModel({
    required this.id,
    required this.vendorName,
    required this.vendorMobile,
    required this.vendorCategory,
    required this.vendorTrader,
    required this.vendorNoOfProducts,
    required this.vendorStatus,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      // Safely parse int and convert string-numbers if needed
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      
      // Safely handle potential nulls by converting to empty strings
      vendorName: json['vendor_name']?.toString() ?? '',
      vendorMobile: json['vendor_mobile']?.toString() ?? '',
      vendorCategory: json['vendor_category']?.toString() ?? '',
      vendorTrader: json['vendor_trader']?.toString() ?? '',
      
      // Safely parse number of products
      vendorNoOfProducts: json['vendor_no_of_products'] is int 
          ? json['vendor_no_of_products'] 
          : int.tryParse(json['vendor_no_of_products']?.toString() ?? '') ?? 0,
      
      vendorStatus: json['vendor_status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_name': vendorName,
      'vendor_mobile': vendorMobile,
      'vendor_category': vendorCategory,
      'vendor_trader': vendorTrader,
      'vendor_no_of_products': vendorNoOfProducts,
      'vendor_status': vendorStatus,
    };
  }
}

/// Fetches the list of vendors from the panel-fetch-vendor-list endpoint.
///
/// Requires the [token] obtained from logging in.
Future<List<VendorModel>> fetchVendorList(String token) async {
  const String url = 'https://kmrlive.in/public/api/panel-fetch-vendor-list';
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      // Retrieve the vendor array (checking both 'vendor' and 'data' keys)
      final List<dynamic>? vendorListJson = data['vendor'] ?? data['data'];
      
      if (vendorListJson != null) {
        return vendorListJson
            .map((item) => VendorModel.fromJson(item))
            .toList();
      }
      return [];
    } else {
      print('Failed to fetch vendors. Status code: ${response.statusCode}');
      print('Response: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching vendor list: $e');
    return [];
  }
}

// Example usage runner
Future<void> main() async {
  const String baseUrl = 'https://kmrlive.in/public/api';
  
  print('--- Step 1: Logging in ---');
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
    print('Failed to get authorization token.');
    return;
  }
  print('Logged in successfully!');

  print('\n--- Step 2: Fetching Vendor List ---');
  List<VendorModel> vendors = await fetchVendorList(token);
  
  print('Successfully fetched and parsed ${vendors.length} vendors.');
  
  // Find and display specific vendors requested
  final targetIds = [11, 76, 53, 72];
  print('\nInspecting requested vendors:');
  for (var vendor in vendors) {
    if (targetIds.contains(vendor.id)) {
      print('- Vendor ID: ${vendor.id}');
      print('  Name: ${vendor.vendorName}');
      print('  Mobile: ${vendor.vendorMobile}');
      print('  Category: ${vendor.vendorCategory}');
      print('  Trader: ${vendor.vendorTrader}');
      print('  No. of Products: ${vendor.vendorNoOfProducts}');
      print('  Status: ${vendor.vendorStatus}\n');
    }
  }
}
