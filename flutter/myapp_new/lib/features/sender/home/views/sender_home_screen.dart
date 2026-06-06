import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

// --- IMPORT ĐỒNG BỘ TỪ CẢ 2 BÊN ---
import 'package:myapp_new/features/sender/tracking/views/tracking_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/services/api_service.dart';
import '../../models/sender_shipment_model.dart';
// 🎯 IMPORT CỤC LEGO CHUÔNG THÔNG BÁO VÀO ĐÂY
import '../../../../shared_widgets/notification_bell.dart'; 

class SenderHomeScreen extends StatefulWidget {
  const SenderHomeScreen({super.key});

  @override
  State<SenderHomeScreen> createState() => _SenderHomeScreenState();
}

class _SenderHomeScreenState extends State<SenderHomeScreen> {
  SenderShipmentModel? activeOrder;
  bool _isLoading = true;
  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrder();
    _checkAndSubscribeVip(); // 💎 Tự động cắm ăng-ten nhận diện VIP
  }

  // ==========================================================
  // 💎 HÀM TỰ ĐỘNG KIỂM TRA HẠNG VIP VÀ ĐĂNG KÝ TOPIC FIREBASE (TỪ XUÂN)
  // ==========================================================
  Future<void> _checkAndSubscribeVip() async {
    try {
      int? userId = await SessionManager.getUserId();
      if (userId == null) return;

      // Gọi API lấy Profile để soi Hạng (Tier) từ ApiService
      final profile = await ApiService.getProfile(userId);

      if (profile != null && profile.tier == 'DIAMOND') {
        await FirebaseMessaging.instance.subscribeToTopic('DIAMOND_SENDERS');
        debugPrint(
          "💎 Đã tự động nhận diện Đại Gia và cắm ăng-ten DIAMOND_SENDERS tại Trang chủ!",
        );
      } else {
        // Lỡ bị giáng cấp hoặc không phải VIP thì hủy để tránh bắt nhầm sóng
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          'DIAMOND_SENDERS',
        );
      }
    } catch (e) {
      debugPrint("❌ Lỗi kiểm tra VIP tại Home: $e");
    }
  }

  // ==========================================================
  // 🌟 HÀM LẤY ĐƠN HÀNG HOẠT ĐỘNG MỚI NHẤT
  // ==========================================================
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

      // Kết hợp logic API gọi lấy đơn hàng an toàn
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Xin chào, Người gửi!", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          // 🔔 Chỉ cần đúng 1 dòng này để hiện cục Lego chuông thay cho đống code cũ
          NotificationBell(), 
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchActiveOrder(); 
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

              // 2. Dịch vụ của chúng tôi
              const Text(
                "Dịch vụ của chúng tôi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  _buildServiceCard(Icons.inventory_2, "Gửi hàng", Colors.blue),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Đơn hàng đang chạy
              const Text(
                "Đơn hàng đang hoạt động",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // 🌟 GIAO DIỆN THẺ ĐƠN HÀNG (GỘP TỪ CẢ 2 BÊN)
  Widget _buildActiveOrderCard(SenderShipmentModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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

          // Điểm lấy hàng
          _buildLocationRow(
            Icons.circle_outlined,
            Colors.orange,
            order.pickupAddress,
          ),

          // Trục dọc phân cách
          Row(
            children: [
              const SizedBox(width: 10),
              Container(width: 1, height: 16, color: Colors.grey[400]),
            ],
          ),

          // Điểm giao hàng
          _buildLocationRow(
            Icons.location_on,
            Colors.red,
            order.dropoffAddress,
          ),

          const SizedBox(height: 16),

          // 🚀 NÚT THEO DÕI CHI TIẾT
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
                // Ép kiểu an toàn
                final int? parsedId = int.tryParse(order.id.toString());

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
            style: const TextStyle(color: Colors.black87, fontSize: 14),
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
      ),
      child: const Center(
        child: Text(
          "Bạn chưa có đơn hàng nào đang chạy",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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