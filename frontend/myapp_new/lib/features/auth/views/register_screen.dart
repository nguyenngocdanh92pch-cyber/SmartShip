import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String selectedRole = 'SENDER';
  bool _isLoading = false;

  // URL của API Gateway
  final String apiGatewayUrl = ApiConfig.baseUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Đã tách thành 2 controller riêng biệt cho phương tiện
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    // Xây dựng payload dựa trên AuthRequest của backend
    Map<String, dynamic> requestBody = {
      'fullName': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': selectedRole,
    };

    if (selectedRole == 'DRIVER') {
      // Gộp 2 ô dữ liệu thành một Map
      Map<String, String> vehicleData = {
        "make": _makeController.text.trim(),
        "plate": _plateController.text.trim(),
      };

      // Chuyển Map thành chuỗi JSON chuẩn để lưu xuống trường jsonb dưới PostgreSQL
      requestBody['vehicleInfo'] = jsonEncode(vehicleData);

      // Phần upload ảnh bằng lái, CCCD sẽ cần xử lý API multipart/form-data riêng sau
    }

    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      // THÊM 2 DÒNG NÀY ĐỂ DEBUG TRÊN TERMINAL VS CODE
      print("Mã trạng thái HTTP: ${response.statusCode}");
      print("Dữ liệu backend trả về: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công!")));
        Navigator.pop(context);
      } else {
        // HIỂN THỊ CHI TIẾT LỖI LÊN MÀN HÌNH ĐỂ DỄ NHÌN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lỗi backend (${response.statusCode}): ${response.body}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Tạo tài khoản",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Chọn vai trò của bạn để bắt đầu",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            _buildRoleSelector(),
            const SizedBox(height: 32),

            // --- THÔNG TIN CHUNG ---
            _buildTextField("Họ và tên", Icons.person, _nameController),
            const SizedBox(height: 16),
            _buildTextField("Số điện thoại", Icons.phone, _phoneController),
            const SizedBox(height: 16),
            _buildTextField(
              "Mật khẩu",
              Icons.lock,
              _passwordController,
              isPassword: true,
            ),

            // --- THÔNG TIN BỔ SUNG CHO TÀI XẾ ---
            if (selectedRole == 'DRIVER') ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.black12, thickness: 1),
              const SizedBox(height: 16),
              const Text(
                "Xác thực Danh tính & Phương tiện",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Đã thay thế thành 2 ô riêng biệt
              _buildTextField(
                "Loại xe (VD: Honda Winner, Ford Transit)",
                Icons.directions_car,
                _makeController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Biển số xe (VD: 59C-123.45)",
                Icons.badge,
                _plateController,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildUploadButton("Chụp CCCD\n(Mặt trước)")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUploadButton("Chụp Bằng lái\nxe")),
                ],
              ),
            ],

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "ĐĂNG KÝ NGAY",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _roleButton("SENDER", "Người Gửi", Icons.inventory_2),
          _roleButton("DRIVER", "Tài Xế", Icons.sports_motorsports),
        ],
      ),
    );
  }

  Widget _roleButton(String role, String label, IconData icon) {
    bool isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
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

  Widget _buildUploadButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.camera_alt, color: Colors.blueAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _makeController.dispose();
    _plateController.dispose();
    super.dispose();
  }
}
