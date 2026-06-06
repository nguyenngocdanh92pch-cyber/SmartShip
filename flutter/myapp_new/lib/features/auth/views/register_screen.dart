import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  // Controller riêng biệt cho phương tiện
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  File? _cccdImage;
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();

  // Hàm gọi Camera hoặc Thư viện dựa trên ImageSource truyền vào
  Future<void> _pickImage(bool isCCCD, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Ép nén mạnh tay xuống 50%
        maxWidth: 1024, // 🎯 QUAN TRỌNG: Giới hạn chiều rộng
        maxHeight: 1024, // 🎯 QUAN TRỌNG: Giới hạn chiều cao
      );
      if (pickedFile != null) {
        setState(() {
          if (isCCCD) {
            _cccdImage = File(pickedFile.path);
          } else {
            _licenseImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy ảnh: $e");
      _showSnackBar("Không thể lấy ảnh: $e");
    }
  }

  // Hàm hiển thị Menu lựa chọn: Chụp ảnh mới HOẶC Chọn từ thư viện
  void _showImageSourceSelection(bool isCCCD) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Chụp ảnh trực tiếp'),
                onTap: () {
                  Navigator.pop(context); // Đóng menu
                  _pickImage(isCCCD, ImageSource.camera); // Mở camera
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Colors.blueAccent,
                ),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context); // Đóng menu
                  _pickImage(isCCCD, ImageSource.gallery); // Mở thư viện máy
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm bổ sung: Upload từng file ảnh lên server và lấy link URL về
  Future<String?> _uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiGatewayUrl/shipments/upload-image'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'] ?? data['data'];
      } else {
        debugPrint("Lỗi upload ảnh từ backend: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Lỗi kết nối upload ảnh: $e");
      return null;
    }
  }

  // Tiện ích hiển thị thông báo nhanh
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin bắt buộc!");
      return;
    }

    if (selectedRole == 'DRIVER') {
      if (_makeController.text.trim().isEmpty ||
          _plateController.text.trim().isEmpty) {
        _showSnackBar("Vui lòng điền đầy đủ thông tin phương tiện!");
        return;
      }
      if (_cccdImage == null || _licenseImage == null) {
        _showSnackBar("Vui lòng bổ sung đủ ảnh CCCD và Bằng lái xe!");
        return;
      }
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> requestBody = {
      'fullName': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': selectedRole,
    };

    try {
      if (selectedRole == 'DRIVER') {
        _showSnackBar("Đang tiến hành tải ảnh xác thực lên hệ thống...");

        String? cccdUrl = await _uploadImage(_cccdImage!);
        String? licenseUrl = await _uploadImage(_licenseImage!);

        if (cccdUrl == null || licenseUrl == null) {
          throw Exception("Tải ảnh xác thực thất bại. Vui lòng thử lại!");
        }

        Map<String, String> vehicleData = {
          "make": _makeController.text.trim(),
          "plate": _plateController.text.trim(),
        };
        requestBody['vehicleInfo'] = jsonEncode(vehicleData);
        requestBody['cccdUrl'] = cccdUrl;
        requestBody['licenseUrl'] = licenseUrl;
      }

      final response = await http.post(
        Uri.parse('$apiGatewayUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      print("Mã trạng thái HTTP: ${response.statusCode}");
      print("Dữ liệu backend trả về: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Đăng ký thành công! Vui lòng đợi Admin phê duyệt.");
        Navigator.pop(context);
      } else {
        _showSnackBar("Lỗi backend (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: $e");
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
                  Expanded(
                    child: _buildUploadButton(
                      "Tải ảnh CCCD\n(Mặt trước)",
                      _cccdImage,
                      () => _showImageSourceSelection(
                        true,
                      ), // Gọi Menu chọn nguồn ảnh
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUploadButton(
                      "Tải ảnh Bằng lái\nxe",
                      _licenseImage,
                      () => _showImageSourceSelection(
                        false,
                      ), // Gọi Menu chọn nguồn ảnh
                    ),
                  ),
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

  Widget _buildUploadButton(String label, File? imageFile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.4)),
                    const Center(
                      child: Text(
                        "Đã chọn thành công\n(Bấm để thay đổi)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
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
