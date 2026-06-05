import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';

class MessagesListScreen extends StatelessWidget {
  final String currentUserId;
  final bool isDriver; // true nếu đang ở app tài xế, false nếu ở app sender

  const MessagesListScreen({
    super.key,
    required this.currentUserId,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Màu nền tối
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe dữ liệu realtime từ Firebase
        stream: FirebaseFirestore.instance
            .collection('ChatRooms')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có cuộc trò chuyện nào',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var roomData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              // Tìm ID của người kia (không phải mình)
              List<dynamic> participants = roomData['participants'];
              String peerId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (peerId.isEmpty) return const SizedBox.shrink();

              // Đọc tên từ Firebase (nếu có)
              String peerName = 'Khách hàng';
              if (roomData['peerNames'] != null &&
                  roomData['peerNames'][peerId] != null) {
                peerName = roomData['peerNames'][peerId];
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: Icon(
                    isDriver ? Icons.person : Icons.local_shipping,
                    color: Colors.blueAccent,
                  ),
                ),
                title: Text(
                  peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  roomData['lastMessage'] ?? 'Bắt đầu trò chuyện',
                  style: const TextStyle(color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Chuyển sang màn hình chat chi tiết khi bấm vào
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        currentUserId: currentUserId,
                        peerId: peerId,
                        peerName: peerName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
