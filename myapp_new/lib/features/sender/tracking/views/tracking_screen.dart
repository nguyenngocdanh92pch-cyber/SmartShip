import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';

// Import màn hình Live Tracking và Màn hình Chat
import 'live_tracking_screen.dart';
import '../../../../shared_widgets/chat_detail_screen.dart';

/// ---------------------------------------------------------------------------
/// MODEL DỮ LIỆU: ĐỒNG BỘ VÀ ÉP KIỂU AN TOÀN TUYỆT ĐỐI (Từ bạn bồ)
/// ---------------------------------------------------------------------------
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
      deliveryLat: parseDoubleSafe(json['deliveryLat'] ?? json['deliveryLatitude']),
      deliveryLng: parseDoubleSafe(json['deliveryLng'] ?? json['deliveryLongitude']),
      packageDescription:
          json['packageDescription']?.toString() ?? 'Không có mô tả',
      shippingCost: parseDoubleSafe(
        json['shippingCost'] ?? json['shippingFee'] ?? json['shipping_fee'],
      ),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      rating: parseIntSafe(json['rating']), // Lấy thêm rating từ bồ
    );
  }
}

/// ---------------------------------------------------------------------------
/// SCREEN: GIAO DIỆN THEO DÕI ĐƠN HÀNG (GỘP CẢ TAB VÀ DETAIL)
/// ---------------------------------------------------------------------------
class TrackingScreen extends StatefulWidget {
  final int? orderId; // 🌟 Cho phép nhận ID đơn hàng từ màn hình khác truyền sang

  const TrackingScreen({super.key, this.orderId});

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

  // 🌟 HÀM TẢI DỮ LIỆU ĐƠN HÀNG KẾT HỢP
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      int? userId = await SessionManager.getUserId();
      if (userId == null) {
        _showSnackBar("Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại!");
        return;
      }

      // Lưu lại thông tin để dùng cho Chat
      _currentUserId = userId.toString();
      _currentUserName = await SessionManager.getFullName();
      String? token = await SessionManager.getToken();

      // Sử dụng API endpoint mới của bạn bồ
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

        // Hỗ trợ parse JSON linh hoạt từ nhiều định dạng trả về của Backend
        if (decodedData is List) {
          rawList = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('content') && decodedData['content'] is List) {
            rawList = decodedData['content'];
          } else if (decodedData.containsKey('data') && decodedData['data'] is List) {
            rawList = decodedData['data'];
          }
        }

        final List<OrderTrackingModel> fetchedOrders = rawList
            .map((json) => OrderTrackingModel.fromJson(json))
            .toList();

        setState(() {
          // Nếu có orderId truyền vào thì chỉ lấy đúng đơn đó
          if (widget.orderId != null) {
            _allOrders = fetchedOrders.where((order) => order.id == widget.orderId).toList();
          } else {
            _allOrders = fetchedOrders;
          }
        });
      } else {
        _showSnackBar("Không thể tải danh sách đơn hàng. Mã lỗi: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      // 🚀 Lột mặt nạ: In thẳng cái lỗi thực sự ra màn hình để trị bệnh
      _showSnackBar("Lỗi thật sự: $e"); 
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
      ),
    );
  }

  // =======================================================================
  // 🎯 LOGIC ĐÁNH GIÁ TÀI XẾ (GIỮ NGUYÊN TỪ BẢN CỦA BỒ)
  // =======================================================================
  void _showRatingDialog(OrderTrackingModel order) {
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          index < selectedStars ? Icons.star : Icons.star_border,
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
                  child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitRating(order.id, selectedStars);
                  },
                  child: const Text("GỬI ĐÁNH GIÁ", style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    // 🌟 Nếu truyền ID vào, giao diện sẽ ẩn TabBar và chỉ hiện 1 đơn duy nhất
    if (widget.orderId != null) {
      return Scaffold(
        backgroundColor: AppColors.senderBackground,
        appBar: AppBar(
          title: const Text("Chi Tiết Đơn Hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildOrderList(_allOrders, "Không tìm thấy đơn hàng yêu cầu"),
      );
    }

    // 🌟 Còn bình thường vào từ Menu thì hiện đủ 2 Tab (Đang giao / Lịch sử)
    final ongoingOrders = _allOrders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED').toList();
    final historyOrders = _allOrders.where((o) => o.status == 'DELIVERED' || o.status == 'CANCELLED').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.senderBackground,
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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
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
                  _buildOrderList(ongoingOrders, "Bạn không có đơn hàng nào đang xử lý"),
                  _buildOrderList(historyOrders, "Bạn chưa có đơn hàng hoàn thành nào"),
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
            Icon(Icons.local_shipping_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage, 
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderTrackingModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // HEADER: MÃ ĐƠN & TRẠNG THÁI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mã đơn: #${order.id}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          
          // GÓI HÀNG
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.packageDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${order.shippingCost.toInt()}đ",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // ĐỊA CHỈ
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // =======================================================
          // 🎯 KHỐI LỊCH SỬ THANH TOÁN VNPay (TỪ CỦA BỒ)
          // =======================================================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text(
                  "Thanh toán: ", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)
                ),
                Text(
                  ['DA_THANH_TOAN', 'PENDING', 'ACCEPTED', 'PICKED_UP', 'AT_WAREHOUSE', 'DELIVERING', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED'].contains(order.status) 
                      ? "Thành công" 
                      : "Chưa thanh toán",
                  style: TextStyle(
                    color: ['DA_THANH_TOAN', 'PENDING', 'ACCEPTED', 'PICKED_UP', 'AT_WAREHOUSE', 'DELIVERING', 'IN_TRANSIT', 'DELIVERED', 'COMPLETED'].contains(order.status) 
                        ? Colors.green.shade700 
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // =======================================================
          // 🎯 KHỐI TÀI XẾ & CHAT & MAP (GIAO DIỆN ĐẸP TỪ BẠN BỒ)
          // =======================================================
          if (order.driverId != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      order.driverName ?? "Tài xế",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Nút Chat
                    if (_currentUserId != null)
                      IconButton(
                        icon: const Icon(Icons.chat_rounded, color: Colors.blue, size: 24),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                currentUserId: _currentUserId!,
                                currentUserName: _currentUserName,
                                peerId: order.driverId!.toString(),
                                peerName: order.driverName ?? "Tài xế",
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // Nút Bản đồ Tracking
                    if (['DELIVERING', 'IN_TRANSIT', 'PICKED_UP'].contains(order.status)) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.map_rounded, color: Colors.green, size: 24),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
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
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],

          // =======================================================
          // 🎯 KHỐI ĐÁNH GIÁ RATING (TỪ CỦA BỒ)
          // =======================================================
          if (order.status == 'AT_WAREHOUSE' || order.status == 'DELIVERED') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            if (order.rating == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade50,
                    foregroundColor: Colors.orange.shade800,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text("Đánh giá Tài xế", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showRatingDialog(order),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Đã đánh giá: ", style: TextStyle(color: Colors.grey)),
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

    switch (backendStatus.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        text = "Đang xử lý";
        break;
      case 'DA_THANH_TOAN':
        color = Colors.green;
        text = "Đã thanh toán";
        break;
      case 'ACCEPTED':
        color = Colors.lightBlue;
        text = "Đã nhận đơn";
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
      case 'IN_TRANSIT':
        color = Colors.teal;
        text = "Đang giao";
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        color = Colors.green;
        text = "Thành công";
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}