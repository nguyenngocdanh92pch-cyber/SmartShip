import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp_new/features/sender/profile/views/chatbot_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/views/login_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../driver/profile/models/user_profile.dart';
import 'payment_methods_screen.dart';
import 'change_password_screen.dart';

class SenderProfileScreen extends StatefulWidget {
  const SenderProfileScreen({super.key});

  @override
  State<SenderProfileScreen> createState() => _SenderProfileScreenState();
}

class _SenderProfileScreenState extends State<SenderProfileScreen> {
  UserProfile? _userProfile;
  String? _fullName;
  String? _phoneNumber;
  bool _isLoading = true;

  // 🌟 CÁC BIẾN QUẢN LÝ ẢNH AVATAR
  File? _localAvatarFile;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      int? currentUserId = await SessionManager.getUserId();
      _fullName = await SessionManager.getFullName() ?? "Người Gửi";
      _phoneNumber =
          await SessionManager.getPhoneNumber() ?? "Chưa cập nhật SĐT";

      if (currentUserId != null) {
        final profile = await ApiService.getProfile(currentUserId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 HÀM CHỌN VÀ UPLOAD AVATAR
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _userProfile != null) {
      setState(() {
        _localAvatarFile = File(image.path);
        _isUploadingAvatar = true; // Hiện loading ngay chỗ avatar
      });

      try {
        // 1. Upload ảnh lên GCS/Cloud
        String? newAvatarUrl = await ApiService.uploadImage(_localAvatarFile!);

        if (newAvatarUrl != null) {
          // 2. Cập nhật URL vào đối tượng Profile
          _userProfile!.avatarUrl = newAvatarUrl;

          // 3. Đẩy thông tin Profile mới xuống Database
          bool success = await ApiService.updateProfile(_userProfile!);

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cập nhật ảnh đại diện thành công!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Lỗi upload avatar: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi tải ảnh lên!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingAvatar = false);
        }
      }
    }
  }

  // 🌟 HÀM SỬA ĐỊA CHỈ (GIỮ NGUYÊN)
  void _editAddress() {
    TextEditingController addressController = TextEditingController(
      text: _userProfile?.defaultAddress ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Sổ địa chỉ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(
              hintText: "Nhập địa chỉ giao/nhận hàng...",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_userProfile != null) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  _userProfile!.defaultAddress = addressController.text.trim();
                  bool success = await ApiService.updateProfile(_userProfile!);

                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? "Cập nhật địa chỉ thành công!"
                              : "Lỗi khi lưu địa chỉ!",
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Lưu thay đổi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String initial = "N";
    if (_fullName != null && _fullName!.isNotEmpty) {
      initial = _fullName!.substring(0, 1).toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Hồ sơ của tôi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 🌟 GIAO DIỆN AVATAR MỚI CÓ THỂ BẤM VÀO
                        GestureDetector(
                          onTap: _isUploadingAvatar
                              ? null
                              : _pickAndUploadAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                backgroundImage: _localAvatarFile != null
                                    ? FileImage(_localAvatarFile!)
                                          as ImageProvider
                                    : (_userProfile?.avatarUrl != null &&
                                          _userProfile!.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_userProfile!.avatarUrl!)
                                    : null,
                                child:
                                    (_localAvatarFile == null &&
                                        (_userProfile?.avatarUrl == null ||
                                            _userProfile!.avatarUrl!.isEmpty))
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isUploadingAvatar)
                                const Positioned(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              if (!_isUploadingAvatar)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName ?? "Người Gửi",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _phoneNumber ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildMenuCard([
                          ListTile(
                            leading: const Icon(
                              Icons.contact_mail,
                              color: AppColors.primary,
                            ),
                            title: const Text(
                              "Sổ địa chỉ",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              (_userProfile?.defaultAddress != null &&
                                      _userProfile!.defaultAddress!.isNotEmpty)
                                  ? _userProfile!.defaultAddress!
                                  : "Chưa thiết lập địa chỉ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    (_userProfile?.defaultAddress != null &&
                                        _userProfile!
                                            .defaultAddress!
                                            .isNotEmpty)
                                    ? Colors.grey.shade700
                                    : Colors.redAccent,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: _editAddress,
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildMenuItem(
                            Icons.payment,
                            "Phương thức thanh toán",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PaymentMethodsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildMenuItem(
                            Icons.local_offer,
                            "Mã khuyến mãi",
                            () {},
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildMenuCard([
                          _buildMenuItem(
                            Icons.settings,
                            "Cài đặt tài khoản (Đổi mật khẩu)", // Sửa tên lại cho rõ ràng
                            () {
                              // 🌟 CHUYỂN SANG MÀN HÌNH ĐỔI MẬT KHẨU
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildMenuItem(
                            Icons.help_outline,
                            "Trung tâm trợ giúp",
                            () {
                              // 🌟 Chuyển hướng sang màn hình Chatbot
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChatbotScreen(), // <-- Đổi thành tên Class màn hình Chatbot của bạn
                                ),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                            ),
                            onPressed: () async {
                              await SessionManager.logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              "ĐĂNG XUẤT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
