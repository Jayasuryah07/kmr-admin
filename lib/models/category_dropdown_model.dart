class CategoryDropdownModel {
  final int id;
  final String categoryName;

  CategoryDropdownModel({
    required this.id,
    required this.categoryName,
  });

  factory CategoryDropdownModel.fromJson(Map<String, dynamic> json) {
    return CategoryDropdownModel(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
    );
  }
}