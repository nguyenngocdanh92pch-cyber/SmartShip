import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:myapp_new/features/sender/tracking/views/tracking_screen.dart';
// ignore: unused_import
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/utils/formatters.dart';
import 'address_search_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _primaryBlue = Color(0xFF1565C0);
const Color _accentBlue = Color(0xFF1E88E5);
const Color _bgColor = Color(0xFFF0F4FF);

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  // ── Address ─────────────────────────────────────────────────────────────────
  String? pickupAddress;
  double? pickupLat;
  double? pickupLng;
  String? deliveryAddress;
  double? deliveryLat;
  double? deliveryLng;

  // ── Controllers ─────────────────────────────────────────────────────────────
  final TextEditingController _packageDescController = TextEditingController();
  final TextEditingController _packageValueController = TextEditingController();

  // ── Vehicle ──────────────────────────────────────────────────────────────────
  String _selectedVehicle = "xe_may";
  final List<Map<String, dynamic>> _vehicles = [
    {
      "id": "xe_may",
      "name": "Xe máy",
      "icon": Icons.motorcycle,
      "desc": "< 30kg",
    },
    {
      "id": "xe_ban_tai",
      "name": "Bán tải",
      "icon": Icons.local_shipping,
      "desc": "< 500kg",
    },
    {
      "id": "xe_tai",
      "name": "Xe tải",
      "icon": Icons.fire_truck,
      "desc": "> 500kg",
    },
  ];

  // ── Voucher & Pricing ────────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedVoucher;

  // 🚀 ĐÃ SỬA: Biến giá tiền thành số 0 mặc định và thêm biến trạng thái Loading
  double _baseShippingFee = 0.0;
  bool _isCalculatingFee = false;

  // ── Image ────────────────────────────────────────────────────────────────────
  File? _selectedImage;
  bool _isLoading = false;

  final String apiGatewayUrl = ApiConfig.baseUrl;

  // ── Step animation ───────────────────────────────────────────────────────────
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _packageDescController.dispose();
    _packageValueController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  double get _discountAmt => _selectedVoucher != null
      ? (_selectedVoucher!['discountAmount'] ?? 0).toDouble()
      : 0.0;
  double get _finalFee =>
      (_baseShippingFee - _discountAmt).clamp(0, double.infinity);

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _selectAddress(bool isPickup) async {
    final result =
        await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddressSearchScreen(
                  title: isPickup
                      ? "Chọn điểm lấy hàng"
                      : "Chọn điểm giao hàng",
                ),
              ),
            )
            as Map<String, dynamic>?;

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupAddress = result['address']?.toString();
          pickupLat = (result['lat'] as num?)?.toDouble();
          pickupLng = (result['lng'] as num?)?.toDouble();
        } else {
          deliveryAddress = result['address']?.toString();
          deliveryLat = (result['lat'] as num?)?.toDouble();
          deliveryLng = (result['lng'] as num?)?.toDouble();
        }
      });

      // 🚀 ĐÃ SỬA: Gọi hàm tính tiền ngay sau khi chọn xong địa chỉ
      _calculateEstimateFee();
    }
  }

  // =========================================================================
  // 🎯 HÀM GỌI API ĐỂ TÍNH TOÁN GIÁ TIỀN TRƯỚC KHI ĐẶT ĐƠN
  // =========================================================================
  Future<void> _calculateEstimateFee() async {
    // Chỉ tính tiền khi đã có đủ 2 tọa độ lấy và giao
    if (pickupLat == null ||
        pickupLng == null ||
        deliveryLat == null ||
        deliveryLng == null) {
      return;
    }

    setState(() {
      _isCalculatingFee = true;
    });

    try {
      // Đã sửa tên tham số tọa độ cho chuẩn với Backend (origin... và dest...)
      final String estimateUrl =
          "$apiGatewayUrl/routing/estimate?originLng=$pickupLng&originLat=$pickupLat&destLng=$deliveryLng&destLat=$deliveryLat&vehicleType=${_selectedVehicle.toUpperCase()}";

      final response = await http.get(Uri.parse(estimateUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Gán giá trị cước phí thực tế Backend trả về
          _baseShippingFee = (data['cost'] ?? data).toDouble();
        });
      } else {
        debugPrint("Lỗi tính phí từ Server: ${response.body}");
        _showSnackBar("Không thể tính cước phí đoạn đường này!", Colors.orange);
      }
    } catch (e) {
      debugPrint("Lỗi gọi API tính phí: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingFee = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Voucher Modal ─────────────────────────────────────────────────────────────
  Future<void> _showVoucherSelectionModal() async {
    String? token = await SessionManager.getToken();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryBlue, _accentBlue],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Chọn Voucher",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade100, height: 20),
            // List
            Expanded(
              child: FutureBuilder<http.Response>(
                future: http.get(
                  Uri.parse("$apiGatewayUrl/shipments/vouchers/available"),
                  headers: token != null
                      ? {'Authorization': 'Bearer $token'}
                      : {},
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryBlue),
                    );
                  }
                  if (snapshot.hasError || snapshot.data!.statusCode != 200) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Không thể tải voucher",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  List vouchers = [];
                  try {
                    vouchers = jsonDecode(
                      utf8.decode(snapshot.data!.bodyBytes),
                    );
                  } catch (e) {
                    debugPrint("Lỗi parse JSON Voucher: $e");
                  }

                  if (vouchers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Hiện chưa có mã giảm giá nào",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) {
                      var v = vouchers[index];
                      String rawDate = v['validUntil'].toString().replaceAll(
                        " T",
                        "T",
                      );
                      if (rawDate.length > 19) {
                        rawDate = rawDate.substring(0, 19);
                      }
                      DateTime validUntil = DateTime.parse(rawDate);
                      String formattedDate =
                          "${validUntil.day.toString().padLeft(2, '0')}/${validUntil.month.toString().padLeft(2, '0')}/${validUntil.year}";
                      double discountAmt = (v['discountAmount'] ?? 0)
                          .toDouble();

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedVoucher = v);
                          Navigator.pop(context);
                          _showSnackBar(
                            "🎉 Đã áp dụng mã ${v['code']} thành công!",
                            Colors.green,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left accent
                              Container(
                                width: 6,
                                height: 80,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [_primaryBlue, _accentBlue],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                ),
                              ),
                              // Ticket hole
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                  ),
                                ),
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['code'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Giảm ${AppFormatters.formatCurrency(discountAmt)}",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "HSD: $formattedDate",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Apply button
                              Container(
                                margin: const EdgeInsets.only(right: 14),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_primaryBlue, _accentBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "DÙNG",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── VNPay ─────────────────────────────────────────────────────────────────────
  Future<void> _processVNPayPayment(int shipmentId, int amount) async {
    try {
      final String paymentApiUrl =
          "$apiGatewayUrl/shipments/payments/create-url?shipmentId=$shipmentId&amount=$amount";
      final response = await http.get(Uri.parse(paymentApiUrl));

      if (response.statusCode == 200) {
        String vnpayUrl = response.body.replaceAll('"', '').trim();

        if (mounted) {
          final paymentResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VNPayWebViewScreen(initialUrl: vnpayUrl),
            ),
          );

          if (paymentResult == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Thanh toán VNPay thành công!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TrackingScreen()),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đã hủy thanh toán hoặc giao dịch thất bại."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        _showSnackBar("Lỗi: Backend không trả link thanh toán", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối VNPay: $e", Colors.red);
    }
  }

  // ── Create Order ──────────────────────────────────────────────────────────────
  Future<void> _handleCreateOrder() async {
    if (pickupAddress == null || deliveryAddress == null) {
      _showSnackBar(
        "Vui lòng thiết lập đầy đủ địa chỉ lấy hàng và giao hàng!",
        Colors.red,
      );
      return;
    }
    if (_packageDescController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng điền mô tả thông tin gói hàng!", Colors.red);
      return;
    }
    if (_selectedImage == null) {
      _showSnackBar("Vui lòng tải lên hình ảnh hàng hóa!", Colors.red);
      return;
    }
    if (_baseShippingFee <= 0) {
      _showSnackBar(
        "Đang tính cước phí, vui lòng đợi giây lát!",
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token = await SessionManager.getToken();
      int? senderId = await SessionManager.getUserId();

      // 🌟 1. NỐI VOUCHER VÀO URL ĐỂ BACKEND DỄ HỨNG (BẰNG @RequestParam)
      String createUrl = '$apiGatewayUrl/shipments/';

      var request = http.MultipartRequest('POST', Uri.parse(createUrl));

      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (senderId != null) request.headers['X-User-Id'] = senderId.toString();

      request.fields['pickupAddress'] = pickupAddress!;
      request.fields['pickupLatitude'] = pickupLat.toString();
      request.fields['pickupLongitude'] = pickupLng.toString();
      request.fields['deliveryAddress'] = deliveryAddress!;
      request.fields['deliveryLatitude'] = deliveryLat.toString();
      request.fields['deliveryLongitude'] = deliveryLng.toString();
      request.fields['packageDescription'] = _packageDescController.text.trim();

      // Vẫn gửi giá nhưng Backend sẽ là người quyết định cuối cùng
      request.fields['shippingFee'] = _finalFee.toString();
      request.fields['vehicleType'] =
          _selectedVehicle; // Gửi chữ thường, không dùng toUpperCase

      if (_packageValueController.text.isNotEmpty) {
        request.fields['packageValue'] = _packageValueController.text.trim();
      }

      // 🌟 2. BẢO HIỂM THÊM: GỬI KÈM DỮ LIỆU VÀO BODY LUÔN CHO CHẮC CÚ
      if (_selectedVoucher != null) {
        request.fields['voucherCode'] = _selectedVoucher!['code'].toString();
      }

      request.files.add(
        await http.MultipartFile.fromPath('images', _selectedImage!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Lấy ID đơn hàng
          int newShipmentId = data['id'] ?? data['data']?['id'] ?? 0;

          // 🌟 3. ÉP KIỂU AN TOÀN TRÁNH BỊ CRASH DO BACKEND TRẢ VỀ SỐ THẬP PHÂN
          num rawCost =
              data['shippingCost'] ?? data['data']?['shippingCost'] ?? 0;
          int shippingCost = rawCost.toInt();

          _showSnackBar(
            "Tạo đơn thành công! Đang chuyển hướng thanh toán...",
            Colors.green,
          );

          // Truyền số tiền CHÍNH THỨC (đã trừ voucher) sang cho VNPay
          if (newShipmentId > 0 && shippingCost > 0) {
            await _processVNPayPayment(newShipmentId, shippingCost);
          } else {
            // Trường hợp khách áp voucher giảm 100% còn 0đ thì không cần qua cổng VNPay nữa
            Navigator.pop(context, true);
          }
        } else {
          _showSnackBar("Tạo đơn thất bại: ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Lỗi hệ thống: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _isLoading ? _buildLoadingOverlay() : _buildBody(),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: _bgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.15),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: _primaryBlue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Đang xử lý đơn hàng...",
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Địa chỉ
              _buildSectionHeader(
                icon: Icons.route_rounded,
                label: "Địa chỉ vận chuyển",
                step: "01",
              ),
              const SizedBox(height: 12),
              _buildAddressCard(),

              const SizedBox(height: 20),

              // 2. Phương tiện
              _buildSectionHeader(
                icon: Icons.commute_rounded,
                label: "Phương tiện vận chuyển",
                step: "02",
              ),
              const SizedBox(height: 12),
              _buildVehicleSelector(),

              const SizedBox(height: 20),

              // 3. Hàng hóa
              _buildSectionHeader(
                icon: Icons.inventory_2_rounded,
                label: "Thông tin gói hàng",
                step: "03",
              ),
              const SizedBox(height: 12),
              _buildPackageCard(),

              const SizedBox(height: 20),

              // 4. Voucher
              _buildSectionHeader(
                icon: Icons.local_offer_rounded,
                label: "Khuyến mãi",
                step: "04",
              ),
              const SizedBox(height: 12),
              _buildVoucherCard(),

              const SizedBox(height: 20),

              // 5. Tổng tiền
              _buildPriceSummaryCard(),

              const SizedBox(height: 24),

              // 6. Nút xác nhận
              _buildConfirmButton(),
            ]),
          ),
        ),
      ],
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Text(
          "",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryBlue, _accentBlue],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.add_box_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Tạo đơn hàng mới",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Điền thông tin để gửi hàng nhanh chóng",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required String step,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primaryBlue, _accentBlue]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _primaryBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Address Card ──────────────────────────────────────────────────────────────
  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAddressRow(
            isPickup: true,
            icon: Icons.radio_button_checked_rounded,
            iconColor: _accentBlue,
            label: pickupAddress ?? "Chọn điểm lấy hàng",
            isPlaceholder: pickupAddress == null,
            onTap: () => _selectAddress(true),
          ),
          // Connector line
          Padding(
            padding: const EdgeInsets.only(left: 27),
            child: Row(
              children: [
                Column(
                  children: List.generate(
                    4,
                    (i) => Container(
                      width: 2,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      color: i.isEven
                          ? _accentBlue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 16,
                  ),
                ),
              ],
            ),
          ),
          _buildAddressRow(
            isPickup: false,
            icon: Icons.location_on_rounded,
            iconColor: Colors.redAccent,
            label: deliveryAddress ?? "Chọn điểm giao hàng",
            isPlaceholder: deliveryAddress == null,
            onTap: () => _selectAddress(false),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required bool isPickup,
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isPickup ? const Radius.circular(16) : Radius.zero,
        bottom: !isPickup ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPickup ? "Lấy hàng tại" : "Giao hàng đến",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isPlaceholder
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: isPlaceholder
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isPlaceholder
                  ? Icons.add_circle_outline_rounded
                  : Icons.edit_rounded,
              size: 18,
              color: isPlaceholder ? _accentBlue : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Vehicle Selector ──────────────────────────────────────────────────────────
  Widget _buildVehicleSelector() {
    return Row(
      children: _vehicles
          .map(
            (v) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildVehicleCard(
                  v['id'] as String,
                  v['name'] as String,
                  v['icon'] as IconData,
                  (v['desc'] ?? '') as String,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildVehicleCard(String id, String name, IconData icon, String desc) {
    bool isSelected = _selectedVehicle == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedVehicle = id);
        // 🚀 ĐÃ SỬA: Tính lại tiền khi đổi xe
        _calculateEstimateFee();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? _primaryBlue : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _primaryBlue : Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? _accentBlue.withOpacity(0.7)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Package Card ──────────────────────────────────────────────────────────────
  Widget _buildPackageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Description field
          _buildFieldRow(
            icon: Icons.inventory_2_rounded,
            iconColor: Colors.orange.shade600,
            label: "Mô tả hàng hóa",
            child: TextField(
              controller: _packageDescController,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: "VD: Quần áo, tài liệu giấy tờ...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            isFirst: true,
          ),
          _buildFieldDivider(),
          // Value field
          _buildFieldRow(
            icon: Icons.monetization_on_rounded,
            iconColor: Colors.green.shade600,
            label: "Giá trị hàng hóa (VNĐ)",
            child: TextField(
              controller: _packageValueController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Không bắt buộc",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _buildFieldDivider(),
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ảnh hàng hóa",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedImage == null
                              ? "Nhấn để tải ảnh lên (bắt buộc)"
                              : "Đã chọn ảnh • Nhấn để thay đổi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedImage == null
                                ? Colors.grey.shade400
                                : _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Image preview or upload icon
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _accentBlue.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        color: _accentBlue.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    bool isFirst = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDivider() =>
      Divider(height: 1, color: Colors.grey.shade100, indent: 64);

  // ── Voucher Card ──────────────────────────────────────────────────────────────
  Widget _buildVoucherCard() {
    final bool hasVoucher = _selectedVoucher != null;
    return GestureDetector(
      onTap: _showVoucherSelectionModal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasVoucher ? Colors.green.shade300 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: hasVoucher
                  ? Colors.green.withOpacity(0.08)
                  : _primaryBlue.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasVoucher
                    ? Colors.green.withOpacity(0.1)
                    : _accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasVoucher
                    ? Icons.check_circle_rounded
                    : Icons.confirmation_number_rounded,
                color: hasVoucher ? Colors.green : _accentBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasVoucher ? "Đã áp dụng mã giảm giá" : "Mã giảm giá",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasVoucher
                        ? "${_selectedVoucher!['code']}  •  -${AppFormatters.formatCurrency(_discountAmt)}"
                        : "Bấm để chọn mã giảm giá",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasVoucher
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (hasVoucher)
              GestureDetector(
                onTap: () => setState(() => _selectedVoucher = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ── Price Summary ─────────────────────────────────────────────────────────────
  Widget _buildPriceSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryBlue, _accentBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                "Chi tiết thanh toán",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 🚀 ĐÃ SỬA: Hiển thị vòng xoay đang tải khi gọi API tính giá
          _isCalculatingFee
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildPriceRow(
                      "Phí vận chuyển",
                      _baseShippingFee > 0
                          ? AppFormatters.formatCurrency(_baseShippingFee)
                          : "---",
                      false,
                    ),
                    if (_discountAmt > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        "Giảm giá voucher",
                        "- ${AppFormatters.formatCurrency(_discountAmt)}",
                        false,
                        valueColor: Colors.greenAccent.shade400,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Tổng thanh toán",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _baseShippingFee > 0
                              ? AppFormatters.formatCurrency(_finalFee)
                              : "---",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isBold, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white.withOpacity(0.9),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── Confirm Button ────────────────────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _primaryBlue, width: 2),
          ),
        ),
        onPressed: _handleCreateOrder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryBlue, _accentBlue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "XÁC NHẬN & THANH TOÁN",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VNPAY WEBVIEW
// ─────────────────────────────────────────────────────────────────────────────
class VNPayWebViewScreen extends StatefulWidget {
  final String initialUrl;
  const VNPayWebViewScreen({super.key, required this.initialUrl});

  @override
  State<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends State<VNPayWebViewScreen> {
  bool _isHandled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thanh toán VNPay",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: _primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  "Bảo mật",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          if (url != null) {
            String currentUrl = url.toString();
            if ((currentUrl.contains("vnp_ResponseCode=00") ||
                    currentUrl.contains("shipments/payments/vnpay-return")) &&
                !_isHandled) {
              _isHandled = true;
              _showSuccessPaymentDialog(context);
            }
          }
        },
      ),
    );
  }

  void _showSuccessPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Thanh toán thành công!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Đơn hàng của bạn đã được thanh toán thành công qua cổng VNPay.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Xem đơn hàng",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
