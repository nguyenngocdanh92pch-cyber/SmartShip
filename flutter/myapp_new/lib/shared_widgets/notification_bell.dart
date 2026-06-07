import 'dart:async'; // Thêm dòng này
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Thêm dòng này
import '../../core/services/api_service.dart';
import '../../core/utils/session_manager.dart';
import '../features/sender/notifications/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  StreamSubscription? _fcmSubscription; // Biến giữ listener

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();

    // 🎧 Lắng nghe thông báo mới khi app đang mở (Foreground)
    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint("🔔 Có thông báo mới tới, cập nhật lại chuông!");
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    // Nhớ dọn dẹp listener khi widget bị hủy để tránh tràn bộ nhớ
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      int? userId = await SessionManager.getUserId();
      if (userId != null) {
        int count = await ApiService.getUnreadNotificationCount(userId);
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy số chấm đỏ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
            _fetchUnreadCount();
          },
        ),

        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
