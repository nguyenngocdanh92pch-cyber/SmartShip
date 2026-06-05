import 'package:flutter/material.dart';

// 🚀 NẠP VŨ KHÍ: Thêm 2 thư viện Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🎯 THÊM THƯ VIỆN NÀY ĐỂ ÉP RỚT CHUÔNG LÚC ĐANG MỞ APP
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'features/auth/views/login_screen.dart';

// 🎯 KHỞI TẠO CÔNG CỤ VẼ THÔNG BÁO CỤC BỘ
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ==============================================================
// 🎯 THÊM 1: HÀM GÁC CỔNG KHI APP TẮT MÀN HÌNH HOẶC CHẠY NGẦM
// (Bắt buộc phải nằm ngoài cùng, TRÊN hàm main)
// ==============================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đánh thức Firebase dậy để xử lý thông báo lúc màn hình đang tắt
  await Firebase.initializeApp(); 
  print("🔔 TING TING! CÓ THÔNG BÁO NGẦM RỚT XUỐNG: ${message.notification?.title}");
}

void main() async {
  // 🚀 BẮT BUỘC: Giúp Flutter gắn kết với hệ thống điện thoại trước khi gọi Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Đánh thức Firebase bằng chìa khóa chuẩn 100%
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAfWFSVBsdukvVIcp09FBgrBdxo8eOOqIs',
      appId: '1:348198744834:android:ac3d6bf62ce3d02bb8081b',
      messagingSenderId: '348198744834',
      projectId: 'smartship-d6392',
    ),
  );

  // ==============================================================
  // 🎯 SETUP KÊNH THÔNG BÁO ƯU TIÊN CAO ĐỂ ÉP NÓ RỚT XUỐNG
  // ==============================================================
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'Kênh này dùng để ép thông báo rớt xuống.', // description
    importance: Importance.high,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ==============================================================
  // 🎯 THÊM 2: XIN QUYỀN GỬI THÔNG BÁO (CỰC KỲ QUAN TRỌNG CHO ANDROID 13+)
  // ==============================================================
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ==============================================================
  // 🎯 THÊM 3: GIAO NHIỆM VỤ CHO NGƯỜI GÁC CỔNG
  // ==============================================================
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ==============================================================
  // 🚀 NÂNG CẤP: HÀM HỨNG THÔNG BÁO KHI APP ĐANG MỞ (Sáng màn hình)
  // ==============================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Nếu có thông báo tới lúc đang mở App -> Lôi đồ nghề ra tự vẽ cái bảng rớt xuống
    if (notification != null && android != null) {
      print('🔔 TING TING! TỰ VẼ BẢNG THÔNG BÁO KHI ĐANG MỞ APP: ${notification.title}');
      
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Giao hàng',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', 
        useMaterial3: true, 
      ),
      home: const LoginScreen(),
    );
  }
}