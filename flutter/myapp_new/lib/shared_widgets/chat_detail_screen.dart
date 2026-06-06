import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName; // 🌟 NHẬN TÊN THẬT (TỪ XUÂN)
  final String peerId;
  final String peerName;

  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String chatRoomId;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Tự động tạo ID phòng chat bằng cách so sánh chuỗi
    chatRoomId = widget.currentUserId.compareTo(widget.peerId) > 0
        ? '${widget.currentUserId}_${widget.peerId}'
        : '${widget.peerId}_${widget.currentUserId}';

    // Theo dõi text để đổi màu nút Send (UI từ bạn)
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });

    // Đánh dấu đã đọc khi vào chat
    _markAsRead();
  }

  void _markAsRead() {
    FirebaseFirestore.instance.collection('ChatRooms').doc(chatRoomId).set({
      'readBy': {widget.currentUserId: true},
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================================================================
  // 🚀 HÀM GỬI TIN NHẮN TÍCH HỢP LOGIC CỦA XUÂN VÀ BẠN
  // ==================================================================
  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    // 🌟 GOM TÊN NHỮNG NGƯỜI ĐÃ BIẾT ĐỂ LƯU VÀO FIREBASE (Logic từ Xuân)
    Map<String, String> namesToSave = {widget.peerId: widget.peerName};
    if (widget.currentUserName != null) {
      namesToSave[widget.currentUserId] = widget.currentUserName!;
    }

    // 1. Thêm tin nhắn vào sub-collection
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

    // 2. Cập nhật ChatRoom tổng, lưu tên hiển thị và đánh dấu người kia chưa đọc
    await FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(chatRoomId)
        .set({
          'participants': [widget.currentUserId, widget.peerId],
          'peerNames': namesToSave, // 🌟 LƯU BẢNG TÊN DỮ LIỆU ĐỘNG
          'lastMessage': message,
          'lastUpdated': FieldValue.serverTimestamp(),
          'readBy': {widget.currentUserId: true, widget.peerId: false},
        }, SetOptions(merge: true));
  }

  // Format giờ:phút cho từng tin nhắn
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Lấy chữ cái đầu của Tên để hiển thị Avatar
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Tạo màu ngẫu nhiên cho Avatar dựa vào Tên
  List<Color> _getAvatarColors(String name) {
    final gradients = [
      [const Color(0xFF6C63FF), const Color(0xFF3B82F6)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF10B981), const Color(0xFF06B6D4)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFF14B8A6), const Color(0xFF6366F1)],
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % gradients.length : 0;
    return gradients[index];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColors = _getAvatarColors(widget.peerName);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14), // Nền Dark mode xịn xò của bạn
      appBar: _buildAppBar(avatarColors),
      body: Column(
        children: [
          // ----------------------------------------------------
          // KHU VỰC HIỂN THỊ TIN NHẮN (LIST VIEW BONG BÓNG)
          // ----------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ChatRooms')
                  .doc(chatRoomId)
                  .collection('Messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải tin nhắn: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyChat(
                    avatarColors,
                  ); // Hiện lời chào khi trống
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Cuộn từ dưới lên cho chuẩn App Chat
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == widget.currentUserId;
                    final Timestamp? ts = messageData['timestamp'];

                    // Kiểm tra xem tin nhắn trước đó có cùng người gửi không để thụt lề cho đẹp
                    bool isFirst = true;
                    if (index < snapshot.data!.docs.length - 1) {
                      var prevData =
                          snapshot.data!.docs[index + 1].data()
                              as Map<String, dynamic>;
                      if (prevData['senderId'] == messageData['senderId']) {
                        isFirst = false;
                      }
                    }

                    return _buildMessageBubble(
                      messageData['content'] ?? '',
                      isMe,
                      ts,
                      isFirst,
                      avatarColors,
                    );
                  },
                );
              },
            ),
          ),
          // ----------------------------------------------------
          // THANH NHẬP TIN NHẮN BÊN DƯỚI
          // ----------------------------------------------------
          _buildInputArea(),
        ],
      ),
    );
  }

  // ==========================================================
  // CÁC COMPONENT UI TUYỆT ĐẸP (GIỮ NGUYÊN TỪ CODE CỦA BẠN)
  // ==========================================================

  PreferredSizeWidget _buildAppBar(List<Color> avatarColors) {
    return AppBar(
      backgroundColor: const Color(0xFF14141F),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: avatarColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(widget.peerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Đang hoạt động',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    String content,
    bool isMe,
    Timestamp? ts,
    bool isFirst,
    List<Color> avatarColors,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 12 : 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (isFirst)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: avatarColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.peerName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 36),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2A2A35),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe
                          ? (isFirst
                                ? const Radius.circular(0)
                                : const Radius.circular(16))
                          : const Radius.circular(16),
                      bottomLeft: !isMe
                          ? (isFirst
                                ? const Radius.circular(0)
                                : const Radius.circular(16))
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isFirst && ts != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      _formatMessageTime(ts),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(List<Color> avatarColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: avatarColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: avatarColors[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(widget.peerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.peerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy gửi lời chào đầu tiên! 👋',
            style: TextStyle(color: Color(0xFF555570), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF14141F),
        border: Border(top: BorderSide(color: Color(0xFF1E1E2C), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A35),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _hasText ? sendMessage : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF2A2A35),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _hasText ? Icons.send : Icons.mic,
                  color: _hasText ? Colors.white : Colors.white54,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
