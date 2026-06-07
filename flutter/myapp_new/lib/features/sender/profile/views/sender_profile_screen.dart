import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../shared_widgets/user_stats_card.dart';
import 'package:myapp_new/features/sender/profile/views/chatbot_screen.dart';
import 'change_password_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/views/login_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../driver/profile/models/user_profile.dart';
import 'payment_methods_screen.dart';

class SenderProfileScreen extends StatefulWidget {
  const SenderProfileScreen({super.key});

  @override
  State<SenderProfileScreen> createState() => _SenderProfileScreenState();
}

class _SenderProfileScreenState extends State<SenderProfileScreen>
    with SingleTickerProviderStateMixin {
  UserProfile? _userProfile;
  String? _fullName;
  String? _phoneNumber;
  bool _isLoading = true;

  String _currentTier = 'BRONZE';
  int _rewardPoints = 0;
  int _totalOrders = 0;

  File? _localAvatarFile;
  bool _isUploadingAvatar = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
            if (profile != null) {
              _currentTier = profile.tier ?? 'BRONZE';
              _rewardPoints = profile.rewardPoints ?? 0;
              _totalOrders = profile.totalOrders ?? 0;
            }
          });

          try {
            if (profile != null && profile.tier == 'DIAMOND') {
              await FirebaseMessaging.instance.subscribeToTopic(
                'DIAMOND_SENDERS',
              );
            }
          } catch (e) {
            debugPrint("Lỗi đăng ký DIAMOND_SENDERS: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _userProfile != null) {
      setState(() {
        _localAvatarFile = File(image.path);
        _isUploadingAvatar = true;
      });

      try {
        String? newAvatarUrl = await ApiService.uploadImage(_localAvatarFile!);
        if (newAvatarUrl != null) {
          _userProfile!.avatarUrl = newAvatarUrl;
          bool success = await ApiService.updateProfile(_userProfile!);
          if (success && mounted) {
            _showSnackBar("Cập nhật ảnh đại diện thành công!", isError: false);
          }
        }
      } catch (e) {
        debugPrint("Lỗi upload avatar: $e");
        if (mounted) _showSnackBar("Lỗi tải ảnh lên!", isError: true);
      } finally {
        if (mounted) setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _editAddress() {
    TextEditingController addressController = TextEditingController(
      text: _userProfile?.defaultAddress ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Sổ địa chỉ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: TextField(
            controller: addressController,
            decoration: InputDecoration(
              hintText: "Nhập địa chỉ giao/nhận hàng...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(
                Icons.edit_location_alt_outlined,
                color: AppColors.primary,
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Hủy",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (_userProfile != null) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  _userProfile!.defaultAddress = addressController.text.trim();
                  bool success = await ApiService.updateProfile(_userProfile!);
                  if (mounted) {
                    setState(() => _isLoading = false);
                    _showSnackBar(
                      success
                          ? "Cập nhật địa chỉ thành công!"
                          : "Lỗi khi lưu địa chỉ!",
                      isError: !success,
                    );
                  }
                }
              },
              child: const Text(
                "Lưu thay đổi",
                style: TextStyle(fontWeight: FontWeight.w600),
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
      backgroundColor: const Color(0xFFF0F4F8),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  slivers: [
                    // ── HEADER ──────────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 240,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Gradient background
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withBlue(
                                      (AppColors.primary.blue + 40).clamp(
                                        0,
                                        255,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Decorative circles
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 40,
                              left: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),
                            // Profile info
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 32),
                                  // Avatar
                                  GestureDetector(
                                    onTap: _isUploadingAvatar
                                        ? null
                                        : _pickAndUploadAvatar,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 46,
                                            backgroundColor: Colors.white,
                                            backgroundImage:
                                                _localAvatarFile != null
                                                ? FileImage(_localAvatarFile!)
                                                      as ImageProvider
                                                : (_userProfile?.avatarUrl !=
                                                          null &&
                                                      _userProfile!
                                                          .avatarUrl!
                                                          .isNotEmpty)
                                                ? NetworkImage(
                                                    _userProfile!.avatarUrl!,
                                                  )
                                                : null,
                                            child:
                                                (_localAvatarFile == null &&
                                                    (_userProfile?.avatarUrl ==
                                                            null ||
                                                        _userProfile!
                                                            .avatarUrl!
                                                            .isEmpty))
                                                ? Text(
                                                    initial,
                                                    style: const TextStyle(
                                                      fontSize: 34,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        if (_isUploadingAvatar)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black26,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        if (!_isUploadingAvatar)
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppColors.primary,
                                              size: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _fullName ?? "Người Gửi",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          color: Colors.white70,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _phoneNumber ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: const Text(
                        "Hồ sơ của tôi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      centerTitle: true,
                    ),

                    // ── BODY ────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats card
                            UserStatsCard(
                              tierName: _currentTier,
                              rewardPoints: _rewardPoints,
                              totalOrders: _totalOrders,
                            ),

                            const SizedBox(height: 24),

                            // Section label
                            _buildSectionLabel("Quản lý tài khoản"),
                            const SizedBox(height: 10),

                            // Menu group 1
                            _buildMenuCard([
                              _buildMenuTile(
                                icon: Icons.location_on_outlined,
                                title: "Sổ địa chỉ",
                                subtitle:
                                    (_userProfile?.defaultAddress != null &&
                                        _userProfile!
                                            .defaultAddress!
                                            .isNotEmpty)
                                    ? _userProfile!.defaultAddress!
                                    : "Chưa thiết lập địa chỉ",
                                subtitleColor:
                                    (_userProfile?.defaultAddress != null &&
                                        _userProfile!
                                            .defaultAddress!
                                            .isNotEmpty)
                                    ? null
                                    : Colors.redAccent,
                                onTap: _editAddress,
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.credit_card_outlined,
                                title: "Phương thức thanh toán",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentMethodsScreen(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.local_offer_outlined,
                                title: "Mã khuyến mãi",
                                onTap: () {},
                              ),
                            ]),

                            const SizedBox(height: 12),

                            // Section label
                            _buildSectionLabel("Hỗ trợ & Bảo mật"),
                            const SizedBox(height: 10),

                            // Menu group 2
                            _buildMenuCard([
                              _buildMenuTile(
                                icon: Icons.lock_outline_rounded,
                                title: "Đổi mật khẩu",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChangePasswordScreen(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.support_agent_rounded,
                                title: "Trung tâm trợ giúp",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatbotScreen(),
                                  ),
                                ),
                              ),
                            ]),

                            const SizedBox(height: 28),

                            // Logout button
                            _buildLogoutButton(),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: subtitleColor ?? Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          "Đăng xuất",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.red.shade100, width: 1.5),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          try {
            await FirebaseMessaging.instance.unsubscribeFromTopic(
              'ALL_SENDERS',
            );
            await FirebaseMessaging.instance.unsubscribeFromTopic(
              'DIAMOND_SENDERS',
            );
            await FirebaseMessaging.instance.unsubscribeFromTopic(
              'ALL_DRIVERS',
            );
          } catch (e) {
            debugPrint("Lỗi hủy Topic: $e");
          }
          await SessionManager.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
