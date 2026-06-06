import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Khởi tạo nullable để tránh LateInitializationError
  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState(); // luôn gọi super trước
    try {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      _fadeAnim = CurvedAnimation(
        parent: _animController!,
        curve: Curves.easeOut,
      );
      _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _animController!, curve: Curves.easeOut),
          );
      _animController!.forward();
    } catch (_) {
      // Nếu animation lỗi, widget vẫn hiển thị bình thường
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin", isError: true);
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
        final data = jsonDecode(response.body);
        final role = data['role'] ?? data['user']?['role'];
        final userId = data['id'] ?? data['user']?['id'];
        final token = data['token'] ?? data['accessToken'];
        final fullName =
            data['fullName'] ?? data['user']?['fullName'] ?? 'Người dùng';

        if (!mounted) return;

        if (userId != null && token != null) {
          int parsedId = userId is int ? userId : int.parse(userId.toString());
          await SessionManager.saveUserSession(parsedId, token.toString());
          await SessionManager.saveFullName(fullName.toString());
          await SessionManager.savePhoneNumber(
            data['phoneNumber'] ??
                data['phone_number'] ??
                "Lỗi: Không có SĐT từ API",
          );
        }

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
        _showSnackBar("Sai số điện thoại hoặc mật khẩu!", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Lỗi kết nối đến máy chủ: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D47A1), // deep blue
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5), // light blue
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Decorative circle top-right ──
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ── Decorative circle bottom-left ──
          Positioned(
            bottom: -80,
            left: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: _fadeAnim != null && _slideAnim != null
                ? FadeTransition(
                    opacity: _fadeAnim!,
                    child: SlideTransition(
                      position: _slideAnim!,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 56),

                            // ── Logo & Brand ──
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "GIAO HÀNG SIÊU TỐC",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Nhanh – Tin cậy – Chuyên nghiệp",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.75),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // ── Card form ──
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0D47A1,
                                    ).withOpacity(0.2),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Chào mừng bạn trở lại!",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Phone field
                                  _buildLabel("Số điện thoại"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    hint: "Nhập số điện thoại",
                                    icon: Icons.phone_android_rounded,
                                    controller: _phoneController,
                                    isPassword: false,
                                  ),
                                  const SizedBox(height: 20),

                                  // Password field
                                  _buildLabel("Mật khẩu"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    hint: "Nhập mật khẩu",
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    isPassword: true,
                                  ),

                                  const SizedBox(height: 32),

                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1565C0,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                key: ValueKey('loading'),
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Row(
                                                key: ValueKey('label'),
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "ĐĂNG NHẬP",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Register link
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Chưa có tài khoản? ",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Đăng ký ngay",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SingleChildScrollView(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF37474F),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: isPassword ? TextInputType.text : TextInputType.phone,
      style: const TextStyle(
        color: Color(0xFF1A237E),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF1565C0).withOpacity(0.12),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
      ),
    );
  }
}
