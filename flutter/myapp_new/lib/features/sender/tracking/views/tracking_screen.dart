import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';

import 'live_tracking_screen.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';
import '../../../../shared_widgets/notification_bell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class OrderTrackingModel {
  final int id;
  final int? driverId;
  final String? driverName;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String packageDescription;
  final double shippingCost;
  final String status;
  final String createdAt;
  final int? rating;

  OrderTrackingModel({
    required this.id,
    this.driverId,
    this.driverName,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.packageDescription,
    required this.shippingCost,
    required this.status,
    required this.createdAt,
    this.rating,
  });

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) {
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return OrderTrackingModel(
      id: parseIntSafe(json['id']) ?? 0,
      driverId:
          parseIntSafe(json['driverId']) ?? parseIntSafe(json['driver_id']),
      driverName:
          json['driverName']?.toString() ??
          json['driver_name']?.toString() ??
          'Tài xế',
      deliveryAddress:
          json['deliveryAddress']?.toString() ?? 'Đang cập nhật địa chỉ...',
      deliveryLat: parseDoubleSafe(
        json['deliveryLat'] ?? json['deliveryLatitude'],
      ),
      deliveryLng: parseDoubleSafe(
        json['deliveryLng'] ?? json['deliveryLongitude'],
      ),
      packageDescription:
          json['packageDescription']?.toString() ?? 'Không có mô tả',
      shippingCost: parseDoubleSafe(
        json['shippingCost'] ?? json['shippingFee'] ?? json['shipping_fee'],
      ),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      rating: parseIntSafe(json['rating']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TrackingScreen extends StatefulWidget {
  final int? orderId;
  const TrackingScreen({super.key, this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<OrderTrackingModel> _allOrders = [];
  final String apiGatewayUrl = ApiConfig.baseUrl;
  String? _currentUserId;
  String? _currentUserName;

  // ── Màu chủ đạo ────────────────────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _accentBlue = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ── Fetch ───────────────────────────────────────────────────────────────────
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      int? userId = await SessionManager.getUserId();
      if (userId == null) {
        _showSnackBar(
          "Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại!",
        );
        return;
      }
      _currentUserId = userId.toString();
      _currentUserName = await SessionManager.getFullName();
      String? token = await SessionManager.getToken();

      final response = await http.get(
        Uri.parse("$apiGatewayUrl/shipments/sender/$userId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> rawList = [];
        if (decodedData is List) {
          rawList = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('content') &&
              decodedData['content'] is List) {
            rawList = decodedData['content'];
          } else if (decodedData.containsKey('data') &&
              decodedData['data'] is List) {
            rawList = decodedData['data'];
          }
        }
        final fetchedOrders = rawList
            .map((j) => OrderTrackingModel.fromJson(j))
            .toList();
        fetchedOrders.sort((a, b) => b.id.compareTo(a.id));
        setState(() {
          _allOrders = widget.orderId != null
              ? fetchedOrders.where((o) => o.id == widget.orderId).toList()
              : fetchedOrders;
        });
      } else {
        _showSnackBar(
          "Không thể tải danh sách đơn hàng. Mã lỗi: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      _showSnackBar("Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Rating ──────────────────────────────────────────────────────────────────
  void _showRatingDialog(OrderTrackingModel order) {
    int selectedStars = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, _accentBlue],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Đánh giá Tài xế",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                "Tài xế ${order.driverName ?? ''} đã phục vụ bạn thế nào?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedStars = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < selectedStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel(selectedStars),
                style: const TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy", style: TextStyle(color: Colors.grey.shade500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _submitRating(order.id, selectedStars);
              },
              child: const Text(
                "Gửi đánh giá",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return "Rất tệ";
      case 2:
        return "Tệ";
      case 3:
        return "Bình thường";
      case 4:
        return "Tốt";
      case 5:
        return "Xuất sắc!";
      default:
        return "";
    }
  }

  Future<void> _submitRating(int orderId, int rating) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await http.post(
        Uri.parse("$apiGatewayUrl/shipments/$orderId/rate?rating=$rating"),
        headers: {'X-User-Id': _currentUserId ?? ""},
      );
      if (mounted) Navigator.pop(context);
      if (response.statusCode == 200) {
        _showSnackBar("Cảm ơn bạn đã đánh giá!", color: Colors.green);
        _fetchOrders();
      } else {
        throw Exception("Lỗi đánh giá");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Lỗi khi gửi đánh giá");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.orderId != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: _buildAppBar("Chi Tiết Đơn Hàng"),
        body: _isLoading
            ? _buildLoadingState()
            : _buildOrderList(_allOrders, "Không tìm thấy đơn hàng yêu cầu"),
      );
    }

    final ongoingOrders = _allOrders
        .where(
          (o) => ![
            'DELIVERED',
            'COMPLETED',
            'CANCELLED',
          ].contains(o.status.toUpperCase()),
        )
        .toList();
    final historyOrders = _allOrders
        .where(
          (o) => [
            'DELIVERED',
            'COMPLETED',
            'CANCELLED',
          ].contains(o.status.toUpperCase()),
        )
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverHeader(ongoingOrders, historyOrders),
          ],
          body: _isLoading
              ? _buildLoadingState()
              : TabBarView(
                  children: [
                    _buildOrderList(
                      ongoingOrders,
                      "Bạn không có đơn hàng nào đang xử lý",
                    ),
                    _buildOrderList(
                      historyOrders,
                      "Bạn chưa có đơn hàng hoàn thành nào",
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Sliver header đẹp với stats ────────────────────────────────────────────
  Widget _buildSliverHeader(
    List<OrderTrackingModel> ongoing,
    List<OrderTrackingModel> history,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryBlue,
      actions: const [NotificationBell()],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryBlue, _accentBlue],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats cards
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.pending_actions_rounded,
                        label: "Đang giao",
                        count: ongoing.length,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.check_circle_rounded,
                        label: "Hoàn thành",
                        count: history
                            .where((o) => o.status.toUpperCase() != 'CANCELLED')
                            .length,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.cancel_rounded,
                        label: "Đã hủy",
                        count: history
                            .where((o) => o.status.toUpperCase() == 'CANCELLED')
                            .length,
                        color: Colors.redAccent.shade100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Collapsed title
      title: const Text(
        "Theo dõi đơn hàng",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: _primaryBlue,
          child: TabBar(
            indicator: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(0),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text("Đang giao (${ongoing.length})"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text("Lịch sử (${history.length})"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: _primaryBlue,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: const [NotificationBell()],
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: _primaryBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Đang tải đơn hàng...",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Order List ──────────────────────────────────────────────────────────────
  Widget _buildOrderList(List<OrderTrackingModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 56,
                color: _primaryBlue.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Kéo xuống để làm mới",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  // ── Order Card ──────────────────────────────────────────────────────────────
  Widget _buildOrderCard(OrderTrackingModel order) {
    final bool isCompleted = [
      'DELIVERED',
      'COMPLETED',
    ].contains(order.status.toUpperCase());
    final bool isCancelled = order.status.toUpperCase() == 'CANCELLED';
    final bool canRate = isCompleted && order.rating == null;

    String formattedDate = "Đang cập nhật";
    try {
      DateTime dt = DateTime.parse(order.createdAt).toLocal();
      formattedDate =
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {}

    final statusInfo = _getStatusInfo(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh màu bên trái theo trạng thái
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusInfo.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              // Nội dung card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row 1: Mã đơn + Badge ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "#${order.id.toString().padLeft(5, '0')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _primaryBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 14),

                      // ── Row 2: Hàng hóa + Giá ───────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 16,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.packageDescription,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${_formatMoney(order.shippingCost)}đ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Row 3: Địa chỉ ───────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // ── Thanh toán ────────────────────────────────────────
                      const SizedBox(height: 10),
                      _buildPaymentRow(order),

                      // ── Tài xế + Actions ──────────────────────────────────
                      if (order.driverId != null) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade100),
                        const SizedBox(height: 12),
                        _buildDriverRow(order),
                      ],

                      // ── Rating ────────────────────────────────────────────
                      if (isCompleted ||
                          order.status.toUpperCase() == 'AT_WAREHOUSE') ...[
                        const SizedBox(height: 12),
                        if (canRate)
                          _buildRateButton(order)
                        else if (order.rating != null)
                          _buildRatingDisplay(order.rating!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(OrderTrackingModel order) {
    final bool isPaid = [
      'PENDING',
      'DA_THANH_TOAN',
      'ACCEPTED',
      'PICKED_UP',
      'AT_WAREHOUSE',
      'DELIVERING',
      'IN_TRANSIT',
      'DELIVERED',
      'COMPLETED',
    ].contains(order.status.toUpperCase());

    return Row(
      children: [
        Icon(
          isPaid
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked,
          size: 14,
          color: isPaid ? Colors.green.shade600 : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          "Thanh toán: ",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          isPaid ? "Thành công" : "Chưa thanh toán",
          style: TextStyle(
            color: isPaid ? Colors.green.shade600 : Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverRow(OrderTrackingModel order) {
    final bool canLiveTrack = [
      'DELIVERING',
      'IN_TRANSIT',
      'PICKED_UP',
    ].contains(order.status.toUpperCase());
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primaryBlue, _accentBlue]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.driverName ?? "Tài xế",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Tài xế phụ trách",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        // Chat button
        if (_currentUserId != null)
          _buildActionIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: _primaryBlue,
            tooltip: "Nhắn tin",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  currentUserId: _currentUserId!,
                  currentUserName: _currentUserName,
                  peerId: order.driverId!.toString(),
                  peerName: order.driverName ?? "Tài xế",
                ),
              ),
            ),
          ),
        // Live tracking button
        if (canLiveTrack) ...[
          const SizedBox(width: 8),
          _buildActionIconButton(
            icon: Icons.my_location_rounded,
            color: Colors.green.shade600,
            tooltip: "Theo dõi GPS",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveTrackingScreen(
                  driverId: order.driverId!,
                  deliveryAddress: order.deliveryAddress,
                  deliveryLat: order.deliveryLat,
                  deliveryLng: order.deliveryLng,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildRateButton(OrderTrackingModel order) {
    return GestureDetector(
      onTap: () => _showRatingDialog(order),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 6),
            Text(
              "Đánh giá tài xế",
              style: TextStyle(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDisplay(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Đã đánh giá: ",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          ...List.generate(
            5,
            (i) => Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Badge ────────────────────────────────────────────────────────────
  _StatusInfo _getStatusInfo(String backendStatus) {
    switch (backendStatus.toUpperCase()) {
      case 'UNPAID':
      case 'AWAITING_PAYMENT':
      case 'PENDING_PAYMENT':
        return _StatusInfo(
          Colors.redAccent,
          "Chờ thanh toán",
          Icons.payment_rounded,
        );
      case 'PENDING':
        return _StatusInfo(
          Colors.orange,
          "Đang xử lý",
          Icons.hourglass_top_rounded,
        );
      case 'DA_THANH_TOAN':
        return _StatusInfo(
          Colors.green,
          "Đã thanh toán",
          Icons.check_circle_rounded,
        );
      case 'ACCEPTED':
        return _StatusInfo(
          const Color(0xFF29B6F6),
          "Tài xế đang đến",
          Icons.directions_bike_rounded,
        );
      case 'PICKED_UP':
        return _StatusInfo(
          const Color(0xFF1E88E5),
          "Đã lấy hàng",
          Icons.inventory_2_rounded,
        );
      case 'DELIVERING':
      case 'IN_TRANSIT':
        return _StatusInfo(
          const Color(0xFF00897B),
          "Đang giao",
          Icons.local_shipping_rounded,
        );
      case 'AT_WAREHOUSE':
        return _StatusInfo(
          const Color(0xFF7E57C2),
          "Tại kho",
          Icons.warehouse_rounded,
        );
      case 'DELIVERED':
      case 'COMPLETED':
        return _StatusInfo(
          Colors.green.shade700,
          "Hoàn thành",
          Icons.check_circle_rounded,
        );
      case 'CANCELLED':
        return _StatusInfo(Colors.red.shade400, "Đã hủy", Icons.cancel_rounded);
      default:
        return _StatusInfo(Colors.grey, "Đang xử lý", Icons.sync_rounded);
    }
  }

  Widget _buildStatusBadge(String backendStatus) {
    final info = _getStatusInfo(backendStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 11, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              color: info.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}K";
    }
    return amount.toInt().toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
class _StatusInfo {
  final Color color;
  final String label;
  final IconData icon;
  const _StatusInfo(this.color, this.label, this.icon);
}
