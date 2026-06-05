import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../models/sender_shipment_model.dart';
import '../../../../core/utils/api_config.dart';

class SenderHomeScreen extends StatefulWidget {
  const SenderHomeScreen({super.key});

  @override
  State<SenderHomeScreen> createState() => _SenderHomeScreenState();
}

class _SenderHomeScreenState extends State<SenderHomeScreen> {
  SenderShipmentModel? activeOrder;
  bool _isLoading = true;
  // Thay vì gán chuỗi cứng như cũ, hãy đổi thành dòng này:
  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrder();
  }

  // Hàm lấy đơn hàng mới nhất đang hoạt động
  Future<void> _fetchActiveOrder() async {
    setState(() => _isLoading = true);
    try {
      String? token = await SessionManager.getToken();
      final response = await http.get(
        Uri.parse("$apiGatewayUrl/api/v1/shipments/latest"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          activeOrder = SenderShipmentModel.fromJson(data);
        });
      } else {
        setState(() => activeOrder = null);
      }
    } catch (e) {
      debugPrint("Lỗi kết nối API: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchActiveOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner khuyến mãi (Giữ nguyên UI cũ)
              _buildPromoBanner(),
              const SizedBox(height: 24),

              // 2. Các dịch vụ chính
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

              // 3. Đơn hàng đang diễn ra (Dữ liệu động)
              const Text(
                "Đơn hàng đang hoạt động",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (activeOrder != null)
                _buildActiveOrderCard(activeOrder!)
              else
                _buildEmptyOrderState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(SenderShipmentModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mã đơn: ${order.id}",
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
          const Divider(height: 24),
          _buildLocationRow(
            Icons.circle_outlined,
            Colors.blue,
            order.pickupAddress,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 9),
            child: SizedBox(height: 20, child: VerticalDivider(thickness: 1)),
          ),
          _buildLocationRow(
            Icons.location_on,
            Colors.red,
            order.dropoffAddress,
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
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
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
