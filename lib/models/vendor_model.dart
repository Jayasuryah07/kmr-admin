class VendorModel {
  final int id;
  final String vendorName;
  final String vendorMobile;
  final String vendorCategory;
  final String vendorTrader;
  final int vendorNoOfProducts;
  String vendorStatus;

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
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vendorName: json['vendor_name']?.toString() ?? '',
      vendorMobile: json['vendor_mobile']?.toString() ?? '',
      vendorCategory: json['vendor_category']?.toString() ?? '',
      vendorTrader: json['vendor_trader']?.toString() ?? '',
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