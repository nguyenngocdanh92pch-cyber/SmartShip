import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String?
  currentUserName; // 🌟 THÊM BIẾN NÀY ĐỂ NHẬN TÊN THẬT (Tài xế hoặc Người gửi)
  final String peerId;
  final String peerName;

  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName, // 🌟 THÊM VÀO CONSTRUCTOR
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    // Tự động tạo ID phòng chat bằng cách so sánh chuỗi (String)
    chatRoomId = widget.currentUserId.compareTo(widget.peerId) > 0
        ? '${widget.currentUserId}_${widget.peerId}'
        : '${widget.peerId}_${widget.currentUserId}';
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    // 1. Tạo tin nhắn mới trong sub-collection
    await FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(chatRoomId)
        .collection('Messages')
        .add({
          'senderId': widget.currentUserId,
          'receiverId': widget.peerId,
          'content': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 🌟 2. Gom tên những người đã biết để lưu (Không gán cứng chữ Tài xế nữa)
    Map<String, String> namesToSave = {widget.peerId: widget.peerName};
    if (widget.currentUserName != null) {
      namesToSave[widget.currentUserId] = widget.currentUserName!;
    }

    // 3. Cập nhật thông tin tổng quan của ChatRoom
    await FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(chatRoomId)
        .set({
          'participants': [widget.currentUserId, widget.peerId],

          // 🌟 LƯU BẢNG TÊN ĐÃ ĐƯỢC GOM DỮ LIỆU ĐỘNG Ở TRÊN
          'peerNames': namesToSave,

          'lastMessage': message,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          widget.peerName,
          style: const TextStyle(
            color: Colors.white, // ĐỔI TÊN Ở TRÊN CÙNG THÀNH MÀU TRẮNG
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // ĐỔI NÚT BACK (MŨI TÊN) THÀNH MÀU TRẮNG
        ),
        backgroundColor: const Color(0xFF2A2A40),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Khu vực hiển thị tin nhắn
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ChatRooms')
                  .doc(chatRoomId)
                  .collection('Messages')
                  .orderBy(
                    'timestamp',
                    descending: true,
                  ) // Sắp xếp tin nhắn mới nhất ở dưới
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Nếu có lỗi
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải tin nhắn: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                // 2. Đang kết nối
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Chưa có tin nhắn
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào.\nHãy gửi lời chào đầu tiên!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                // 4. Đã có tin nhắn
                return ListView.builder(
                  reverse: true, // Cuộn từ dưới lên
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : const Color(0xFF2A2A40),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                            bottomLeft: !isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          messageData['content'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Khu vực nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            color: const Color(0xFF2A2A40),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
