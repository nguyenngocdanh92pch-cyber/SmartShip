import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp_new/features/sender/tracking/views/tracking_screen.dart';
import 'package:myapp_new/features/sender/notifications/notification_screen.dart'; // 🔔 Thêm màn hình thông báo
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 Thêm Firebase
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/services/api_service.dart'; // 🎯 Thêm ApiService để check VIP & đếm thông báo
import '../../models/sender_shipment_model.dart';

class SenderHomeScreen extends StatefulWidget {
  const SenderHomeScreen({super.key});

  @override
  State<SenderHomeScreen> createState() => _SenderHomeScreenState();
}

class _SenderHomeScreenState extends State<SenderHomeScreen> {
  SenderShipmentModel? activeOrder;
  bool _isLoading = true;
  final String apiGatewayUrl = ApiConfig.baseUrl;

  // 🎯 Biến lưu số lượng thông báo chưa đọc từ bản của bạn hữu
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrder();
    _loadUnreadCount();     // 🔔 Tải số thông báo chưa đọc
    _checkAndSubscribeVip(); // 💎 Tự động cắm ăng-ten nhận diện VIP
  }

  // ==========================================================
  // 💎 HÀM TỰ ĐỘNG KIỂM TRA HẠNG VIP VÀ ĐĂNG KÝ TOPIC FIREBASE
  // ==========================================================
  Future<void> _checkAndSubscribeVip() async {
    try {
      int? userId = await SessionManager.getUserId();
      if (userId == null) return;

      // Gọi API lấy Profile để soi Hạng (Tier) từ ApiService
      final profile = await ApiService.getProfile(userId);
      
      if (profile != null && profile.tier == 'DIAMOND') {
        await FirebaseMessaging.instance.subscribeToTopic('DIAMOND_SENDERS');
        debugPrint("💎 Đã tự động nhận diện Đại Gia và cắm ăng-ten DIAMOND_SENDERS tại Trang chủ!");
      } else {
        // Lỡ bị giáng cấp hoặc không phải VIP thì hủy để tránh bắt nhầm sóng
        await FirebaseMessaging.instance.unsubscribeFromTopic('DIAMOND_SENDERS');
      }
    } catch (e) {
      debugPrint("❌ Lỗi kiểm tra VIP tại Home: $e");
    }
  }

  // ==========================================================
  // 🔔 HÀM ĐẾM SỐ THÔNG BÁO CHƯA ĐỌC
  // ==========================================================
  Future<void> _loadUnreadCount() async {
    int? userId = await SessionManager.getUserId();
    if (userId != null && mounted) {
      int count = await ApiService.getUnreadNotificationCount(userId);
      setState(() => unreadCount = count);
    }
  }

  // 🌟 HÀM LẤY ĐƠN HÀNG HOẠT ĐỘNG MỚI NHẤT (Giữ nguyên Endpoint chuẩn của bạn)
  Future<void> _fetchActiveOrder() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String? token = await SessionManager.getToken();
      int? senderId = await SessionManager.getUserId();

      if (senderId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse("$apiGatewayUrl/shipments/sender/$senderId/latest"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData != null && decodedData is Map<String, dynamic>) {
          setState(() {
            activeOrder = SenderShipmentModel.fromJson(decodedData);
          });
        } else {
          setState(() => activeOrder = null);
        }
      } else {
        setState(() => activeOrder = null);
      }
    } catch (e) {
      debugPrint("Lỗi khi tải đơn hàng hoạt động: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.senderBackground, // Giữ màu nền của bạn
      appBar: AppBar(
        title: const Text(
          "Trang Chủ Người Gửi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Nút Refresh của bạn
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchActiveOrder();
              _loadUnreadCount();
            },
          ),
          // 🔔 Nút Chuông Thông Báo kèm Chấm Đỏ từ bản voucher của bạn hữu
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0, // Chỉ hiển thị khi có thông báo chưa đọc
              label: Text(unreadCount.toString()), 
              child: const Icon(Icons.notifications_active),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ).then((value) => _loadUnreadCount()); // Đóng danh sách thì tải lại số chấm đỏ
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchActiveOrder();
          await _loadUnreadCount(); // Vuốt xuống để cập nhật lại cả hai dữ liệu
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner khuyến mãi
              _buildPromoBanner(),
              const SizedBox(height: 24),

              // 2. 🎯 Thêm mục "Dịch vụ của chúng tôi" kế thừa từ bản của bạn hữu
              const Text(
                "Dịch vụ của chúng tôi",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildServiceCard(
                    Icons.local_shipping,
                    "Giao nhanh",
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildServiceCard(
                    Icons.inventory_2, 
                    "Gửi hàng", 
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Đơn hàng đang chạy của bạn
              const Text(
                "Đơn hàng đang chạy",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : activeOrder != null
                      ? _buildActiveOrderCard(activeOrder!)
                      : _buildEmptyOrderState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(SenderShipmentModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mã đơn: #${order.id}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    color: order.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _buildLocationRow(Icons.circle, Colors.orange, order.pickupAddress),

          // 🌟 Giữ nguyên logic vẽ vạch dọc độc quyền của bạn không sợ lỗi UI
          Row(
            children: [
              const SizedBox(width: 10), 
              Container(
                width: 1, 
                height: 12, 
                color: Colors.grey[400], 
              ),
            ],
          ),

          _buildLocationRow(
            Icons.location_on,
            Colors.red,
            order.dropoffAddress,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.track_changes_rounded,
                color: Colors.white,
              ),
              label: const Text(
                "Theo dõi chi tiết",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // 🌟 Logic ép kiểu an toàn tuyệt đối của bạn
                final int? parsedId = int.tryParse(order.id);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingScreen(orderId: parsedId), 
                  ),
                ).then((_) => _fetchActiveOrder()); 
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOrderState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          "Bạn chưa có đơn hàng nào đang chạy",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // 🎯 Tích hợp hàm xây dựng thẻ Dịch vụ từ code bạn hữu
  Widget _buildServiceCard(IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          "Giảm 20% cho đơn hàng đầu tiên!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}