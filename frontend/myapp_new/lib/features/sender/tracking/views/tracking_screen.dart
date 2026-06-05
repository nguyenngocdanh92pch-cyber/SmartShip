import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';

// Import màn hình Live Tracking và Màn hình Chat
import 'live_tracking_screen.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';

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
    return OrderTrackingModel(
      id: json['id'] ?? 0,
      driverId: json['driverId'],
      driverName: json['driverName'] ?? json['driver_name'] ?? 'Tài xế',
      deliveryAddress: json['deliveryAddress'] ?? 'Đang cập nhật địa chỉ...',
      deliveryLat: (json['deliveryLatitude'] ?? 0.0).toDouble(),
      deliveryLng: (json['deliveryLongitude'] ?? 0.0).toDouble(),
      packageDescription: json['packageDescription'] ?? '',
      shippingCost: (json['shippingCost'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      rating: json['rating'],
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isLoading = true;
  List<OrderTrackingModel> _allOrders = [];
  final String apiGatewayUrl = ApiConfig.baseUrl;

  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      int? userId = await SessionManager.getUserId();

      _currentUserId = userId?.toString();
      _currentUserName = await SessionManager.getFullName();

      final response = await http.get(
        Uri.parse("$apiGatewayUrl/shipments/history"),
        headers: {'X-User-Id': userId.toString()},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allOrders = data
              .map((json) => OrderTrackingModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Không thể tải danh sách đơn hàng");
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi kết nối máy chủ!")));
      }
    }
  }

  void _showRatingDialog(OrderTrackingModel order) {
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Đánh giá Tài xế",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Chuyến đi của bạn thế nào?\nHãy đánh giá tài xế ${order.driverName ?? ''}",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedStars
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedStars = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "HỦY",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitRating(order.id, selectedStars);
                  },
                  child: const Text(
                    "GỬI ĐÁNH GIÁ",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cảm ơn bạn đã đánh giá!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchOrders();
      } else {
        throw Exception("Lỗi đánh giá");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi khi gửi đánh giá"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 LOGIC ĐÃ SỬA: Đang giao là tất cả các đơn NGOẠI TRỪ Đã Giao và Đã Hủy
    final ongoingOrders = _allOrders.where((o) {
      return o.status != 'DELIVERED' && o.status != 'CANCELLED';
    }).toList();

    // 🌟 LOGIC ĐÃ SỬA: Lịch sử CHỈ CHỨA Đã Giao và Đã Hủy
    final historyOrders = _allOrders.where((o) {
      return o.status == 'DELIVERED' || o.status == 'CANCELLED';
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            "Theo dõi đơn hàng",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Đang giao"),
              Tab(text: "Lịch sử"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _buildOrderList(List<OrderTrackingModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderTrackingModel order) {
    bool canChat =
        (order.status == 'ACCEPTED' ||
            order.status == 'PICKED_UP' ||
            order.status == 'DELIVERING' ||
            order.status == 'AT_WAREHOUSE') && // AT_WAREHOUSE vẫn được chat
        order.driverId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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

              Row(
                children: [
                  if (canChat && _currentUserId != null)
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blueAccent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserId: _currentUserId!,
                              currentUserName: _currentUserName,
                              peerId: order.driverId!.toString(),
                              peerName: order.driverName ?? 'Tài xế',
                            ),
                          ),
                        );
                      },
                    ),
                  if (canChat) const SizedBox(width: 8),

                  GestureDetector(
                    onTap: () {
                      if (canChat) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveTrackingScreen(
                              driverId: order.driverId!,
                              deliveryAddress: order.deliveryAddress,
                              deliveryLat: order.deliveryLat,
                              deliveryLng: order.deliveryLng,
                            ),
                          ),
                        );
                      } else if (order.driverId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đơn hàng chưa có tài xế nhận!"),
                          ),
                        );
                      }
                    },
                    child: _buildStatusBadge(order.status),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.packageDescription,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${order.shippingCost.toInt()}đ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          if ((order.status == 'AT_WAREHOUSE' ||
              order.status == 'DELIVERED')) ...[
            const Divider(height: 24),
            if (order.rating == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade100,
                    foregroundColor: Colors.orange.shade800,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text(
                    "Đánh giá Tài xế",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showRatingDialog(order),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Đã đánh giá: ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < order.rating! ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String backendStatus) {
    Color color;
    String text;

    switch (backendStatus) {
      case 'PENDING':
        color = Colors.orange;
        text = "Đang xử lý";
        break;
      case 'ACCEPTED':
        color = Colors.lightBlue;
        text = "Đã nhận";
        break;
      case 'PICKED_UP':
        color = Colors.blue;
        text = "Đã lấy hàng";
        break;
      case 'AT_WAREHOUSE':
        color = Colors.purple;
        text = "Tại kho";
        break;
      case 'DELIVERING':
        color = Colors.teal;
        text = "Đang giao";
        break;
      case 'DELIVERED':
        color = Colors.green;
        text = "Đã giao";
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = "Đã hủy";
        break;
      default:
        color = Colors.grey;
        text = "Không xác định";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
