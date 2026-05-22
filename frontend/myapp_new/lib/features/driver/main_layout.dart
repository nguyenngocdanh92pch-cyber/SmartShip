import 'package:flutter/material.dart';
import 'orders/views/orders_view.dart';
import '../../core/theme/app_colors.dart';
import 'home/views/home_screen.dart';
import 'messages/views/messages_screen.dart';
import 'earnings/views/earnings_screen.dart';
import 'profile/views/profile_screen.dart';
import '../../core/utils/session_manager.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String? _currentUserId; // Biến lưu ID người dùng thật

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Gọi hàm lấy ID ngay khi màn hình khởi tạo
  }

  // Hàm bất đồng bộ để đọc ID từ SharedPreferences
  Future<void> _loadUserId() async {
    int? id = await SessionManager.getUserId();
    if (id != null) {
      setState(() {
        // Firebase yêu cầu String nên ép kiểu int sang String
        _currentUserId = id.toString();
      });
    }
  }

  // Chuyển danh sách các màn hình thành getter (get _screens)
  // để tự động cập nhật giao diện khi _currentUserId có dữ liệu
  List<Widget> get _screens => [
    const HomeScreen(), // Tab 0: Bản đồ & Nhận đơn
    OrdersView(isActive: _currentIndex == 1),
    // Tab 2: Tin nhắn
    _currentUserId == null
        ? const Center(
            child: CircularProgressIndicator(),
          ) // Hiện loading trong lúc chờ lấy ID
        : MessagesListScreen(
            currentUserId: _currentUserId!, // Đã có ID thật từ Session
            isDriver: true,
          ),

    const EarningsScreen(), // Tab 3: Thu nhập & Ví
    const ProfileScreen(), // Tab 4: Hồ sơ & Xác minh
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Sử dụng IndexedStack để không bị load lại trang khi chuyển Tab
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Cấu hình giao diện đồng nhất với AppColors
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed, // Cố định 5 icon
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 20,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              activeIcon: Icon(Icons.directions_run),
              label: 'Lộ trình',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Thu nhập',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
