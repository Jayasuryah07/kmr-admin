class VendorLiveModel {
  final int id;
  final int vendorId;
  final String vendorName;
  final String vendorTrader;
  final String vendorProductCategory;
  final String vendorProductCategorySub;
  final String vendorProduct;
  final String vendorProductSize;
  final num vendorProductRate;
  String vendorProductStatus;
  final String vendorProductCreatedDate;
  final String vendorProductCreatedTime;
  final String vendorProductUpdatedDate;
  final String vendorProductUpdatedTime;

  VendorLiveModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorTrader,
    required this.vendorProductCategory,
    required this.vendorProductCategorySub,
    required this.vendorProduct,
    required this.vendorProductSize,
    required this.vendorProductRate,
    required this.vendorProductStatus,
    required this.vendorProductCreatedDate,
    required this.vendorProductCreatedTime,
    required this.vendorProductUpdatedDate,
    required this.vendorProductUpdatedTime,
  });

  factory VendorLiveModel.fromJson(Map<String, dynamic> json) {
    return VendorLiveModel(
      id: json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vendorId: json['vendor_id'] is int 
          ? json['vendor_id'] 
          : int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      vendorName: json['vendor_name']?.toString() ?? '',
      vendorTrader: json['vendor_trader']?.toString() ?? '',
      vendorProductCategory: json['vendor_product_category']?.toString() ?? '',
      vendorProductCategorySub: json['vendor_product_category_sub']?.toString() ?? '',
      vendorProduct: json['vendor_product']?.toString() ?? '',
      vendorProductSize: json['vendor_product_size']?.toString() ?? '',
      vendorProductRate: json['vendor_product_rate'] is num 
          ? json['vendor_product_rate'] 
          : num.tryParse(json['vendor_product_rate']?.toString() ?? '') ?? 0,
      vendorProductStatus: json['vendor_product_status']?.toString() ?? 'Active',
      vendorProductCreatedDate: json['vendor_product_created_date']?.toString() ?? '',
      vendorProductCreatedTime: json['vendor_product_created_time']?.toString() ?? '',
      vendorProductUpdatedDate: json['vendor_product_updated_date']?.toString() ?? '',
      vendorProductUpdatedTime: json['vendor_product_updated_time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_trader': vendorTrader,
      'vendor_product_category': vendorProductCategory,
      'vendor_product_category_sub': vendorProductCategorySub,
      'vendor_product': vendorProduct,
      'vendor_product_size': vendorProductSize,
      'vendor_product_rate': vendorProductRate,
      'vendor_product_status': vendorProductStatus,
      'vendor_product_created_date': vendorProductCreatedDate,
      'vendor_product_created_time': vendorProductCreatedTime,
      'vendor_product_updated_date': vendorProductUpdatedDate,
      'vendor_product_updated_time': vendorProductUpdatedTime,
    };
  }
}
