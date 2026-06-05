import 'package:flutter/material.dart';

// Import màn hình đăng nhập (Nơi app sẽ bắt đầu)
// Nếu dòng này bị đỏ, hãy xóa nó đi, trỏ chuột vào chữ LoginScreen ở dưới và bấm Ctrl + .
import 'features/auth/views/login_screen.dart';

import 'package:firebase_core/firebase_core.dart'; // Import lõi Firebase
import 'firebase_options.dart'; // Import file cấu hình vừa được sinh ra

// Đổi hàm main thành async
void main() async {
  // Bắt buộc gọi dòng này trước khi khởi tạo Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình tự động
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Giao hàng',
      debugShowCheckedModeBanner: false, // Tắt chữ "DEBUG" ở góc trên bên phải
      theme: ThemeData(
        // Cấu hình phông chữ và màu sắc mặc định cho toàn app
        primarySwatch: Colors.blue,
        fontFamily:
            'Roboto', // Có thể đổi sang font khác nếu bạn đã thêm font vào dự án
        useMaterial3: true, // Sử dụng Material Design 3 hiện đại
      ),
      // Màn hình đầu tiên xuất hiện khi mở App là LoginScreen
      home: const LoginScreen(),
    );
  }
}
