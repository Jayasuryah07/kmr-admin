class SubCategoryModel {
  final int id;
  final int? categorySubSort;
  final int? categoryId;
  final String categoryName;
  final String categorySubName;
  String categorySubStatus;
  final String? categoriesSubImages;

  SubCategoryModel({
    required this.id,
    this.categorySubSort,
    this.categoryId,
    required this.categoryName,
    required this.categorySubName,
    required this.categorySubStatus,
    this.categoriesSubImages,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug
    print('Parsing SubCategory: ${json['category_sub_name']}');
    
    return SubCategoryModel(
      id: json['id'] ?? 0,
      categorySubSort: json['category_sub_sort'],
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name'] ?? '',
      categorySubName: json['category_sub_name'] ?? '',
      categorySubStatus: json['category_sub_status'] ?? 'Active',
      categoriesSubImages: json['categories_sub_images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_sub_sort': categorySubSort,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_sub_name': categorySubName,
      'category_sub_status': categorySubStatus,
      'categories_sub_images': categoriesSubImages,
    };
  }
}