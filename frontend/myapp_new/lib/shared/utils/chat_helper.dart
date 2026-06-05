// lib/shared/utils/chat_helper.dart
String getChatRoomId(String user1, String user2) {
  // Sắp xếp ID theo alphabet để luôn tạo ra chuỗi giống nhau
  if (user1.compareTo(user2) > 0) {
    return '${user1}_$user2';
  } else {
    return '${user2}_$user1';
  }
}
