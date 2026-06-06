import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = "userId";
  static const String _keyToken = "token"; // Thêm key để lưu token
  static const String _keyIsLoggedIn = "isLoggedIn";

  // Cập nhật hàm này để lưu cả token khi đăng nhập thành công
  static Future<void> saveUserSession(int userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyToken, token); // Lưu token
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // Lấy Token xác thực
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Lấy ID người dùng đang đăng nhập
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Kiểm tra đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Đăng xuất (Xóa sạch dữ liệu)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Lưu tên vào bộ nhớ tạm của điện thoại
  static Future<void> saveFullName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('FULL_NAME', name);
  }

  // Lấy tên ra
  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('FULL_NAME');
  }

  // Lưu số điện thoại (bạn có thể gọi hàm này ở màn hình Đăng nhập)
  static Future<void> savePhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phone);
  }

  // Lấy số điện thoại ra để hiển thị ở Profile
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone_number');
  }

  // 🌟 LƯU TRẠNG THÁI ONLINE CỦA TÀI XẾ
  static Future<void> saveDriverOnlineStatus(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_online_status', isOnline);
  }

  // 🌟 LẤY TRẠNG THÁI ONLINE
  static Future<bool> getDriverOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('driver_online_status') ??
        false; // Mặc định là Offline
  }
}
