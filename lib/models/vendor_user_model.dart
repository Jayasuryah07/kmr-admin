class VendorUserModel {
  final int id;
  final String name;
  final String mobile;
  final String email;
  String status;
  final String? remarks;

  VendorUserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.status,
    this.remarks,
  });

  factory VendorUserModel.fromJson(Map<String, dynamic> json) {
    return VendorUserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Active',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'status': status,
      'remarks': remarks,
    };
  }
}