import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/views/login_screen.dart';
import '../models/user_profile.dart';
import 'identity_verification_screen.dart';
import '../../payments/views/payments_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  String? _myName; // 🌟 BIẾN ĐỂ HỨNG TÊN TỪ SESSION

  File? _localAvatarFile;

  // Xóa _nameController vì Tên không cho phép sửa nữa
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    int? currentUserId = await SessionManager.getUserId();

    // 🌟 LẤY TÊN TỪ SESSION RA
    _myName = await SessionManager.getFullName();

    if (currentUserId != null) {
      final profile = await ApiService.getProfile(currentUserId);
      setState(() {
        _userProfile = profile;
        // Chỉ điền địa chỉ để edit
        _addressController.text = profile?.defaultAddress ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _localAvatarFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null) return;

    setState(() => _isSaving = true);

    try {
      if (_localAvatarFile != null) {
        String? newAvatarUrl = await ApiService.uploadImage(_localAvatarFile!);
        if (newAvatarUrl != null) {
          _userProfile!.avatarUrl = newAvatarUrl;
        }
      }

      // Chỉ cập nhật địa chỉ, KHÔNG cập nhật Tên
      _userProfile!.defaultAddress = _addressController.text.trim();

      bool success = await ApiService.updateProfile(_userProfile!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lưu thông tin thành công!")),
          );
          _loadUserProfile();
          setState(() => _localAvatarFile = null);
        }
      } else {
        throw Exception("API trả về false");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi khi lưu thông tin!")));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _handleSignOut() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            "Không thể tải dữ liệu",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. AVATAR ---
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _localAvatarFile != null
                        ? FileImage(_localAvatarFile!) as ImageProvider
                        : (_userProfile!.avatarUrl != null
                              ? NetworkImage(_userProfile!.avatarUrl!)
                              : null),
                    child:
                        (_localAvatarFile == null &&
                            _userProfile!.avatarUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. HỌ TÊN (CHỈ ĐỌC - LẤY TỪ SESSION) ---
            Text(
              _myName ?? "Đang tải...", // 🌟 HIỂN THỊ TÊN TỪ SESSION Ở ĐÂY
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Làm cho chữ to ra chút
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. REWARD POINTS (DỮ LIỆU ĐỘNG TỪ DB) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0047AB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reward Points",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // GẮN BIẾN rewardPoints VÀ tier TỪ MODEL VÀO ĐÂY
                      Text(
                        "${_userProfile!.rewardPoints ?? 0} PTS | ${_userProfile!.tier ?? 'BRONZE'} Tier",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 4. ĐỊA CHỈ (EDITABLE) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Default Address",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Nhập địa chỉ của bạn...",
                      hintStyle: TextStyle(color: Colors.white38),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 5. MENU CHỨC NĂNG ---
            _buildMenuItem(
              title: "Vehicles & Docs",
              icon: Icons.directions_car_outlined,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        IdentityVerificationScreen(userProfile: _userProfile!),
                  ),
                );
                _loadUserProfile();
              },
            ),
            const Divider(color: AppColors.surface, height: 1),
            _buildMenuItem(
              title: "Payments",
              icon: Icons.credit_card_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentsScreen()),
              ),
            ),
            const SizedBox(height: 32),

            // --- 6. NÚT LƯU & ĐĂNG XUẤT ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        "SAVE PROFILE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleSignOut,
                child: const Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
