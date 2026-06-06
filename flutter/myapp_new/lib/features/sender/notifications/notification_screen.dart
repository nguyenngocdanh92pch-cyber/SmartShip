import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/session_manager.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    int? userId = await SessionManager.getUserId();
    if (userId != null) {
      try {
        final data = await ApiService.getMyNotifications(userId);
        if (mounted) {
          setState(() {
            notifications = data;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Lỗi tải thông báo: $e");
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🎯 MÁY DỊCH THỜI GIAN ĐÃ ĐƯỢC LẮP ĐẶT
  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'Vừa xong';
    try {
      DateTime parsed = DateTime.parse(rawDate).toLocal();
      String day = parsed.day.toString().padLeft(2, '0');
      String month = parsed.month.toString().padLeft(2, '0');
      String hour = parsed.hour.toString().padLeft(2, '0');
      String minute = parsed.minute.toString().padLeft(2, '0');
      return '$hour:$minute - $day/$month/${parsed.year}';
    } catch (e) {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Thông báo", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blueAccent, 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : notifications.isEmpty 
            ? const Center(
                child: Text(
                  "Bạn chưa có thông báo nào",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  bool isRead = item['is_read'] ?? item['isRead'] ?? item['read'] ?? false;
                  
                  // 🎯 GOM HẾT CÁC TÊN BIẾN THỜI GIAN ĐỂ DỊCH
                  String formattedDate = _formatDate(
                    item['sentAt'] ?? item['sent_at'] ?? item['createdAt'] ?? item['created_at']
                  );

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      item['title'] ?? 'Thông báo mới',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.grey.shade700 : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['body'] ?? '',
                            style: TextStyle(
                              color: isRead ? Colors.grey.shade600 : Colors.black87,
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // 🎯 IN NGÀY GIỜ RA GIAO DIỆN DANH SÁCH
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    tileColor: isRead ? Colors.white : Colors.blue.shade50, 
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                      child: Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : Colors.blueAccent,
                      ),
                    ),
                    onTap: () async {
                      // 1. Chuyển sang màn hình Chi tiết
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailScreen(
                            title: item['title'] ?? 'Thông báo',
                            body: item['body'] ?? '',
                            date: formattedDate, // 🎯 TRUYỀN NGÀY GIỜ ĐÃ DỊCH SANG TRANG CHI TIẾT
                          ),
                        ),
                      );

                      // 2. Chạy ngầm API đánh dấu đã đọc
                      if (!isRead) {
                        await ApiService.markNotificationAsRead(item['id']);
                        setState(() {
                          notifications[index]['is_read'] = true;
                          notifications[index]['isRead'] = true;
                          notifications[index]['read'] = true;
                        });
                      }
                    },
                  );
                },
              ),
    );
  }
}

// =========================================================================
// 🎯 MÀN HÌNH CHI TIẾT THÔNG BÁO (Đã xóa bản trùng lặp, giữ lại bản xịn)
// =========================================================================
class NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String date;

  const NotificationDetailScreen({
    super.key,
    required this.title,
    required this.body,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết thông báo", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            Text(
              body,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}