import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/session_manager.dart'; // Thêm import SessionManager
import 'message/views/messages_screen.dart';

import 'create_order/create_order_screen.dart';
import 'home/views/sender_home_screen.dart';
import 'tracking/views/tracking_screen.dart';
import 'profile/views/sender_profile_screen.dart';

class MainLayoutSender extends StatefulWidget {
  const MainLayoutSender({super.key});

  @override
  State<MainLayoutSender> createState() => _MainLayoutSenderState();
}

class _MainLayoutSenderState extends State<MainLayoutSender> {
  int _currentIndex = 0;
  String? _currentUserId; // Biến lưu ID người dùng để truyền vào màn hình chat

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Hàm lấy ID người dùng hiện tại
  Future<void> _loadUserId() async {
    int? userId = await SessionManager.getUserId();
    if (userId != null && mounted) {
      setState(() {
        _currentUserId = userId.toString();
      });
    }
  }

  // Sử dụng method (hàm) thay vì list cố định để có thể truyền _currentUserId vào
  List<Widget> _buildScreens() {
    return [
      const SenderHomeScreen(), // Tab 0: Trang chủ
      const TrackingScreen(), // Tab 1: Đơn hàng (Dời sang cạnh Trang chủ)
      // Tab 2: Tin nhắn
      _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : MessagesListScreen(
              currentUserId: _currentUserId!,
              isDriver: false, // Đây là app của Người gửi
            ),

      const SenderProfileScreen(), // Tab 3: Hồ sơ
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.senderBackground,
      // Sử dụng IndexedStack để giữ nguyên vị trí cuộn khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(), // Gọi hàm lấy danh sách màn hình
      ),

      // Nút Tạo đơn hàng (FloatingActionButton) nằm nổi ở giữa BottomBar
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          );
        },
        elevation: 6,
        child: const Icon(Icons.add_box, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppColors.senderSurface,
        shape: const CircularNotchedRectangle(), // Tạo đường cong lõm
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // --- NHÓM BÊN TRÁI ---
              _buildNavItem(
                icon: Icons.home_rounded,
                label: "Trang chủ",
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.local_shipping_rounded,
                label: "Đơn hàng",
                index: 1, // Đã dời sang vị trí số 1
              ),

              // Khoảng trống ở giữa cho nút FAB
              const SizedBox(width: 40),

              // --- NHÓM BÊN PHẢI ---
              _buildNavItem(
                icon: Icons.chat_bubble_rounded, // Icon tin nhắn
                label: "Tin nhắn",
                index: 2, // Vị trí số 2
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: "Hồ sơ",
                index: 3, // Dời hồ sơ sang số 3
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
