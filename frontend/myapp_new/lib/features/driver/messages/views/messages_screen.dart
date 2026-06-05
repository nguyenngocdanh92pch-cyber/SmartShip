import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';

class MessagesListScreen extends StatelessWidget {
  final String currentUserId;
  final bool isDriver;

  const MessagesListScreen({
    super.key,
    required this.currentUserId,
    required this.isDriver,
  });

  // Lấy 2 chữ cái đầu để làm avatar chữ
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Chọn màu gradient avatar dựa theo tên (nhất quán cho từng người)
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

  // Format thời gian kiểu Messenger: hôm nay → giờ:phút, khác → ngày/tháng
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays < 7) {
      const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[dt.weekday % 7];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ChatRooms')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var roomData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              List<dynamic> participants = roomData['participants'] ?? [];
              String peerId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              if (peerId.isEmpty) return const SizedBox.shrink();

              String peerName = 'Khách hàng';
              if (roomData['peerNames'] != null &&
                  roomData['peerNames'][peerId] != null) {
                peerName = roomData['peerNames'][peerId];
              }

              // Kiểm tra tin nhắn chưa đọc
              final readBy = roomData['readBy'];
              final bool isUnread =
                  readBy == null ||
                  !(readBy is Map && readBy[currentUserId] == true);

              final String lastMessage =
                  roomData['lastMessage'] ?? 'Bắt đầu trò chuyện';
              final Timestamp? lastUpdated = roomData['lastUpdated'];
              final String timeStr = _formatTime(lastUpdated);
              final colors = _getAvatarColors(peerName);

              return _buildConversationTile(
                context,
                peerId: peerId,
                peerName: peerName,
                lastMessage: lastMessage,
                timeStr: timeStr,
                isUnread: isUnread,
                avatarColors: colors,
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A14),
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'Tin nhắn',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
            onPressed: () {},
            tooltip: 'Tin nhắn mới',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: TextStyle(color: Color(0xFF555570), fontSize: 15),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF555570),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context, {
    required String peerId,
    required String peerName,
    required String lastMessage,
    required String timeStr,
    required bool isUnread,
    required List<Color> avatarColors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Đánh dấu đã đọc khi mở chat
          FirebaseFirestore.instance
              .collection('ChatRooms')
              .doc(
                currentUserId.compareTo(peerId) > 0
                    ? '${currentUserId}_$peerId'
                    : '${peerId}_$currentUserId',
              )
              .set({
                'readBy': {currentUserId: true},
              }, SetOptions(merge: true));

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
        splashColor: const Color(0xFF6C63FF).withOpacity(0.08),
        highlightColor: const Color(0xFF6C63FF).withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: avatarColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: avatarColors[0].withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(peerName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Online dot (có thể kết nối với presence system sau)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF0A0A14),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          peerName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isUnread
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF555570),
                            fontSize: 12,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isUnread
                                  ? const Color(0xFFD4D4E8)
                                  : const Color(0xFF555570),
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có cuộc trò chuyện',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu nhắn tin với ai đó nào!',
            style: TextStyle(color: Color(0xFF555570), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonTile(),
    );
  }

  Widget _buildSkeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161624),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              'Lỗi kết nối: $error',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
