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
  bool _obscurePassword = true;

  final String apiGatewayUrl = ApiConfig.baseUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  File? _cccdImage;
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();

  // ── Màu chủ đạo (khớp với Login) ──────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _accentBlue = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFF42A5F5);

  // ── Image picking ──────────────────────────────────────────────────────────
  Future<void> _pickImage(bool isCCCD, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
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

  void _showImageSourceSelection(bool isCCCD) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: _accentBlue),
                  ),
                  title: const Text(
                    'Chụp ảnh trực tiếp',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isCCCD, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: _accentBlue),
                  ),
                  title: const Text(
                    'Chọn ảnh từ thư viện',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isCCCD, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        _showSnackBar("Đang tải ảnh xác thực lên hệ thống...");
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Đăng ký thành công! Vui lòng đợi Admin phê duyệt.");
        Navigator.pop(context);
      } else {
        _showSnackBar("Lỗi (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient nền giống trang Login
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryBlue, _accentBlue, _lightBlue],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(),

              // ── Scrollable card ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tiêu đề card
                          const Text(
                            "Đăng ký",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Tạo tài khoản mới để bắt đầu!",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // Role selector
                          _buildRoleSelector(),
                          const SizedBox(height: 20),

                          // Form fields
                          _buildLabel("Họ và tên"),
                          const SizedBox(height: 6),
                          _buildTextField(
                            "Nhập họ và tên",
                            Icons.person_outline,
                            _nameController,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Số điện thoại"),
                          const SizedBox(height: 6),
                          _buildTextField(
                            "Nhập số điện thoại",
                            Icons.phone_iphone_outlined,
                            _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Mật khẩu"),
                          const SizedBox(height: 6),
                          _buildPasswordField(),

                          // ── Phần tài xế ───────────────────────────────
                          if (selectedRole == 'DRIVER') ...[
                            const SizedBox(height: 24),
                            _buildDriverSection(),
                          ],

                          const SizedBox(height: 28),

                          // Nút đăng ký
                          _buildRegisterButton(),

                          const SizedBox(height: 20),

                          // Link quay lại đăng nhập
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Đã có tài khoản? ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "Đăng nhập ngay",
                                  style: TextStyle(
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Logo icon (khớp Login)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "GIAO HÀNG SIÊU TỐC",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Nhanh – Tin cậy – Chuyên nghiệp",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Label nhỏ phía trên field ─────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  // ── Role Selector ─────────────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleButton('SENDER', 'Người Gửi', Icons.inventory_2_outlined),
          _roleButton('DRIVER', 'Tài Xế', Icons.sports_motorsports_outlined),
        ],
      ),
    );
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final bool isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryBlue.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text Field (khớp style Login) ─────────────────────────────────────────
  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: "Nhập mật khẩu",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey.shade400,
          size: 20,
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 2),
        ),
      ),
    );
  }

  // ── Phần thông tin tài xế ─────────────────────────────────────────────────
  Widget _buildDriverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider có nhãn
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.directions_car, color: _primaryBlue, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Thông tin phương tiện",
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabel("Loại xe"),
        const SizedBox(height: 6),
        _buildTextField(
          "VD: Honda Winner, Ford Transit",
          Icons.directions_car_outlined,
          _makeController,
        ),
        const SizedBox(height: 16),

        _buildLabel("Biển số xe"),
        const SizedBox(height: 6),
        _buildTextField(
          "VD: 59C-123.45",
          Icons.badge_outlined,
          _plateController,
        ),
        const SizedBox(height: 20),

        // Upload ảnh
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      color: _primaryBlue,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Xác thực danh tính",
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildUploadButton(
                "CCCD\n(Mặt trước)",
                Icons.credit_card_outlined,
                _cccdImage,
                () => _showImageSourceSelection(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUploadButton(
                "Bằng lái xe",
                Icons.drive_eta_outlined,
                _licenseImage,
                () => _showImageSourceSelection(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Upload button ─────────────────────────────────────────────────────────
  Widget _buildUploadButton(
    String label,
    IconData icon,
    File? imageFile,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: imageFile != null
              ? Colors.transparent
              : _accentBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: imageFile != null
                ? Colors.green.shade400
                : _accentBlue.withOpacity(0.3),
            width: imageFile != null ? 2 : 1.5,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.35)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Đã chọn\n(Bấm để đổi)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: _accentBlue, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _accentBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Nhấn để tải lên",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Register button ───────────────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_primaryBlue, _accentBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ĐĂNG KÝ NGAY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
