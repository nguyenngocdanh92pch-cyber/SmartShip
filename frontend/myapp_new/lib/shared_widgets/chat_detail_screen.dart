import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;
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
    chatRoomId = widget.currentUserId.compareTo(widget.peerId) > 0
        ? '${widget.currentUserId}_${widget.peerId}'
        : '${widget.peerId}_${widget.currentUserId}';

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

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    Map<String, String> namesToSave = {widget.peerId: widget.peerName};
    if (widget.currentUserName != null) {
      namesToSave[widget.currentUserId] = widget.currentUserName!;
    }

    // Thêm tin nhắn vào sub-collection
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

    // Cập nhật ChatRoom, reset readBy (peer chưa đọc)
    await FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(chatRoomId)
        .set({
          'participants': [widget.currentUserId, widget.peerId],
          'peerNames': namesToSave,
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

  // Lấy chữ cái đầu avatar
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

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
      backgroundColor: const Color(0xFF0A0A14),
      appBar: _buildAppBar(avatarColors),
      body: Column(
        children: [
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
                      'Lỗi: ${snapshot.error}',
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
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
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

                    // Nhóm: kiểm tra xem tin nhắn trước có cùng người gửi không
                    bool isFirst = true;
                    if (index < snapshot.data!.docs.length - 1) {
                      final prevData =
                          snapshot.data!.docs[index + 1].data()
                              as Map<String, dynamic>;
                      isFirst = prevData['senderId'] != messageData['senderId'];
                    }

                    return _buildMessageBubble(
                      content: messageData['content'] ?? '',
                      isMe: isMe,
                      timeStr: _formatMessageTime(ts),
                      isFirst: isFirst,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(List<Color> avatarColors) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
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
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.peerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF6C63FF)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Color(0xFF6C63FF)),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF1C1C2E)),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isMe,
    required String timeStr,
    required bool isFirst,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 8 : 2, bottom: 2),
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
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getAvatarColors(widget.peerName),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.peerName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                        isMe ? 18 : (isFirst ? 4 : 18),
                      ),
                      bottomRight: Radius.circular(
                        isMe ? (isFirst ? 4 : 18) : 18,
                      ),
                    ),
                    boxShadow: isMe
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFFD4D4E8),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        color: Color(0xFF444460),
                        fontSize: 11,
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

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        border: const Border(
          top: BorderSide(color: Color(0xFF1C1C2E), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Nút emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.emoji_emotions_outlined,
              color: Color(0xFF555570),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Ô nhập
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Color(0xFF444460), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nút gửi / like
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('like'),
                    onTap: () {
                      _messageController.text = '👍';
                      sendMessage();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Text('👍', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    final avatarColors = _getAvatarColors(widget.peerName);
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
}
