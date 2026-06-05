import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/driver/profile/models/user_profile.dart';
import '../utils/api_config.dart';

class ApiService {
  // Thay đổi port này bằng port cấu hình của API Gateway (ví dụ 8080)
  static const String gatewayUrl = '${ApiConfig.baseUrl}/users';

  // Lấy thông tin user
  static Future<UserProfile?> getProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/me?userId=$userId'),
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  // Upload ảnh lên Google Cloud thông qua API 1
  static Future<String?> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$gatewayUrl/upload-image'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return responseData; // Đây là Public URL trả về từ GcsService
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
    return null;
  }

  // Cập nhật hồ sơ (API 2)
  static Future<bool> updateProfile(UserProfile profile) async {
    try {
      final response = await http.put(
        Uri.parse('$gatewayUrl/me'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(profile.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }
}
