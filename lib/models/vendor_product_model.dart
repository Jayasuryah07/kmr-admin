class VendorProductModel {
  final String subCategory;
  final String productName;
  final String size;
  final String rate;

  VendorProductModel({
    required this.subCategory,
    required this.productName,
    required this.size,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'sub_category': subCategory,
      'product_name': productName,
      'size': size,
      'rate': rate,
    };
  }
}