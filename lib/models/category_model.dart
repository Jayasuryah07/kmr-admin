class CategoryModel {
  final int id;
  final int? categorySort;
  final String categoryName;
  final String? categoriesImages;
  String categoryStatus;

  CategoryModel({
    required this.id,
    this.categorySort,
    required this.categoryName,
    this.categoriesImages,
    required this.categoryStatus,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      categorySort: json['category_sort'],
      categoryName: json['category_name'] ?? '',
      categoriesImages: json['categories_images'],
      categoryStatus: json['category_status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_sort': categorySort,
      'category_name': categoryName,
      'categories_images': categoriesImages,
      'category_status': categoryStatus,
    };
  }
}