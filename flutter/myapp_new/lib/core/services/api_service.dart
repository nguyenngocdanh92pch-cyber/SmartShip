import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/driver/profile/models/user_profile.dart';
import '../utils/api_config.dart';
import '../../core/utils/session_manager.dart';

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

  // =========================================================
  // 1. Hàm lấy số lượng chấm đỏ (Đã thêm Token)
  // =========================================================
  static Future<int> getUnreadNotificationCount(int userId) async {
    try {
      String? token = await SessionManager.getToken(); // Lấy chìa khóa

      // 🟢 THÊM LOG ĐỂ KIỂM TRA
      print("🔔 [TEST API CHUÔNG] Đang gọi API lấy số chấm đỏ cho User: $userId");
      print("🔔 [TEST API CHUÔNG] Token hiện tại: ${token != null ? 'Đã có token' : 'NULL'}");

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/unread-count/$userId'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      // 🟢 IN RA KẾT QUẢ TỪ BACKEND
      print("🔔 [TEST API CHUÔNG] Mã trạng thái (Status Code): ${response.statusCode}");
      print("🔔 [TEST API CHUÔNG] Dữ liệu Backend trả về: ${response.body}");
      
      if (response.statusCode == 200) {
        return int.tryParse(response.body) ?? 0;
      }
    } catch (e) {
      print("Lỗi đếm thông báo: $e");
    }
    return 0;
  }

  // =========================================================
  // 2. Hàm lấy danh sách thông báo (Đã thêm Token + Bóc vỏ JSON)
  // =========================================================
  static Future<List<dynamic>> getMyNotifications(int userId) async {
    try {
      String? token = await SessionManager.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/me/$userId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // Thuật toán bóc vỏ JSON phòng khi Backend phân trang
        if (decoded is List) return decoded;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('content') && decoded['content'] is List) return decoded['content'];
          if (decoded.containsKey('data') && decoded['data'] is List) return decoded['data'];
        }
      } else {
        print("Lỗi tải thông báo từ server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi lấy danh sách thông báo: $e");
    }
    return [];
  }

  // =========================================================
  // 3. Hàm đánh dấu thông báo đã đọc (Đã thêm Token)
  // =========================================================
  static Future<bool> markNotificationAsRead(int logId) async {
    try {
      String? token = await SessionManager.getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$logId/read'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi khi đánh dấu đã đọc: $e");
      return false;
    }
  }
}