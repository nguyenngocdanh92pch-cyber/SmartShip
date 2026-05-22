class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role; // 'DRIVER' hoặc 'SENDER'
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.avatarUrl,
  });

  // Chuyển đổi từ JSON (khi gọi API login/register)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'SENDER',
      avatarUrl: json['avatarUrl'],
    );
  }

  // Kiểm tra vai trò
  bool get isDriver => role == 'DRIVER';
}