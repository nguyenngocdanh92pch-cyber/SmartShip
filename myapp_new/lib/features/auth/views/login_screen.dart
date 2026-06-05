import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// 🎯 THÊM DÒNG NÀY ĐỂ GỌI FIREBASE
import 'package:firebase_messaging/firebase_messaging.dart'; 

import '../../driver/main_layout.dart';
import '../../sender/main_layout_sender.dart';
import 'register_screen.dart';
import '../../../core/utils/session_manager.dart'; 
import '../../../../core/utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // URL của API Gateway
  final String apiGatewayUrl = ApiConfig.baseUrl;

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Parse dữ liệu từ AuthResponse của backend
        final data = jsonDecode(response.body);

        // Lấy role, userId, token và TIER (Hạng thành viên)
        final role = data['role'] ?? data['user']?['role'];
        final userId = data['id'] ?? data['user']?['id'];
        final token = data['token'] ?? data['accessToken'];
        
        // 🎯 LẤY THÊM TIER ĐỂ XÉT VIP
        final tier = data['tier'] ?? data['user']?['tier']; 

        // LẤY THÊM FULLNAME TỪ BACKEND TRẢ VỀ
        final fullName = data['fullName'] ?? data['user']?['fullName'] ?? 'Người dùng';

        if (!mounted) return;

        // Lưu userId, token và tên vào bộ nhớ đệm (Session)
        if (userId != null && token != null) {
          int parsedId = userId is int ? userId : int.parse(userId.toString());
          await SessionManager.saveUserSession(parsedId, token.toString());
          await SessionManager.saveFullName(fullName.toString());
          await SessionManager.savePhoneNumber(
            data['phoneNumber'] ?? data['phone_number'] ?? "Lỗi: Không có SĐT từ API",
          );
        }

        // =========================================================
        // 🎯 BƯỚC 3: ĐĂNG KÝ "HỘ KHẨU" FIREBASE ĐỂ NHẬN THÔNG BÁO
        // =========================================================
        try {
          // XÓA SÓNG CŨ (Rất quan trọng để tránh nhận nhầm thông báo của tk khác)
          await FirebaseMessaging.instance.unsubscribeFromTopic('ALL_SENDERS');
          await FirebaseMessaging.instance.unsubscribeFromTopic('ALL_DRIVERS');
          await FirebaseMessaging.instance.unsubscribeFromTopic('DIAMOND_SENDERS');

          if (role == 'SENDER') {
            // 1. Khách hàng nào cũng vào nhóm ALL_SENDERS
            await FirebaseMessaging.instance.subscribeToTopic('ALL_SENDERS');
            debugPrint("✅ Đã đăng ký Topic: ALL_SENDERS");

            // 2. Nếu là VIP (KIM CƯƠNG) thì vào thêm nhóm DIAMOND_SENDERS
            if (tier == 'DIAMOND') {
              await FirebaseMessaging.instance.subscribeToTopic('DIAMOND_SENDERS');
              debugPrint("💎 Đã đăng ký Topic: DIAMOND_SENDERS");
            }
          } else if (role == 'DRIVER') {
            // 3. Tài xế thì vào nhóm ALL_DRIVERS
            await FirebaseMessaging.instance.subscribeToTopic('ALL_DRIVERS');
            debugPrint("🛵 Đã đăng ký Topic: ALL_DRIVERS");
          }
        } catch (e) {
          debugPrint("❌ Lỗi đăng ký Firebase Topic: $e");
        }
        // =========================================================

        // Điều hướng tự động dựa trên role
        if (role == 'DRIVER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayoutSender()),
          );
        }
      } else {
        if (!mounted) return;
        
        // 🌟 BỎ KÍNH HIỂN VI - THAY BẰNG THÔNG BÁO LỊCH SỰ
        String errorMessage = "Đăng nhập thất bại. Vui lòng kiểm tra lại!";
        
        try {
          // Cố gắng đọc câu báo lỗi (message) từ Spring Boot gửi về
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message']; 
          }
        } catch (_) {
          // Nếu Backend không trả về JSON mà trả text thuần
          if (response.body.isNotEmpty && response.body.length < 100) {
            errorMessage = response.body;
          }
        }

        // Hiện thông báo lỗi xịn sò bằng SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối đến máy chủ: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.local_shipping,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                "GIAO HÀNG SIÊU TỐC",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 60),

              _buildTextField("Số điện thoại", Icons.phone, _phoneController, false),
              const SizedBox(height: 16),
              _buildTextField("Mật khẩu", Icons.lock, _passwordController, true),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "ĐĂNG NHẬP",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "Chưa có tài khoản? Đăng ký ngay",
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}