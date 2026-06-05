import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// --- IMPORT ĐỒNG BỘ TỪ CẢ 2 BÊN ---
import 'package:myapp_new/features/sender/tracking/views/tracking_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/utils/formatters.dart';
import 'address_search_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  // --- 1. BIẾN LƯU TRỮ ĐỊA CHỈ TỪ MAPBOX ---
  String? pickupAddress;
  double? pickupLat;
  double? pickupLng;

  String? deliveryAddress;
  double? deliveryLat;
  double? deliveryLng;

  // --- 2. HỘP ĐIỀU KHIỂN DỮ LIỆU NHẬP VÀO ---
  final TextEditingController _packageDescController = TextEditingController();
  final TextEditingController _packageValueController = TextEditingController();

  // --- 3. QUẢN LÝ TRẠNG THÁI VOUCHER (ĐÃ NÂNG CẤP THÀNH OBJECT) ---
  Map<String, dynamic>? _selectedVoucher; 
  final double _baseShippingFee = 50000.0; // Phí vận chuyển gốc mặc định

  // --- 4. TRẠNG THÁI HỆ THỐNG BIẾN TOÀN CỤC ---
  File? _selectedImage;
  bool _isLoading = false;

  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void dispose() {
    _packageDescController.dispose();
    _packageValueController.dispose();
    super.dispose();
  }

  // 📸 HÀM CHỌN ẢNH TỪ THƯ VIỆN
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 🌟 HÀM MỞ MÀN HÌNH TÌM KIẾM ĐỊA CHỈ MAPBOX
  Future<void> _selectAddress(bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSearchScreen(
          title: isPickup ? "Chọn điểm lấy hàng" : "Chọn điểm giao hàng",
        ),
      ),
    ) as Map<String, dynamic>?;

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
    }
  }

  // =========================================================================
  // 🎟️ HÀM GỌI API & HIỂN THỊ DANH SÁCH VOUCHER (BOTTOM SHEET)
  // =========================================================================
  Future<void> _showVoucherSelectionModal() async {
    String? token = await SessionManager.getToken();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse("$apiGatewayUrl/shipments/vouchers/available"),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError || snapshot.data!.statusCode != 200) {
              return const SizedBox(height: 300, child: Center(child: Text("Không thể tải danh sách voucher!")));
            }

            List vouchers = [];
            try {
              vouchers = jsonDecode(utf8.decode(snapshot.data!.bodyBytes));
            } catch (e) {
              debugPrint("Lỗi parse JSON Voucher: $e");
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: 450, // Chiều cao của bảng
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Chọn Voucher Khả Dụng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  vouchers.isEmpty
                      ? const Expanded(child: Center(child: Text("Hiện chưa có mã giảm giá nào.", style: TextStyle(color: Colors.grey))))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: vouchers.length,
                            itemBuilder: (context, index) {
                              var v = vouchers[index];
                              
                              // 🛡️ ĐÃ FIX: Lọc sạch rác ngày tháng trước khi Parse
                              String rawDate = v['validUntil'].toString();
                              rawDate = rawDate.replaceAll(" T", "T"); // Xóa khoảng trắng trước chữ T nếu có
                              if (rawDate.length > 19) {
                                rawDate = rawDate.substring(0, 19); // Cắt bỏ phần lặp thời gian dư thừa ở đuôi
                              }

                              // Format ngày giờ đẹp hiển thị cho khách
                              DateTime validUntil = DateTime.parse(rawDate);
                              String formattedDate = "${validUntil.day.toString().padLeft(2, '0')}/${validUntil.month.toString().padLeft(2, '0')}/${validUntil.year} ${validUntil.hour.toString().padLeft(2, '0')}:${validUntil.minute.toString().padLeft(2, '0')}";
                              double discountAmt = (v['discountAmount'] ?? 0).toDouble();

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                                color: Colors.blue.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.blue.shade200),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.confirmation_number, color: Colors.blue, size: 36),
                                  title: Text(
                                    v['code'], // Mã in hoa (VD: CUOITUAN20K)
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text("Giảm ngay: ${AppFormatters.formatCurrency(discountAmt)}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text("HSD: $formattedDate", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text("DÙNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() {
                                        _selectedVoucher = v; // 🎯 LƯU VOUCHER VÀO STATE
                                      });
                                      Navigator.pop(context); // Đóng bảng
                                      _showSnackBar("🎉 Đã áp dụng mã ${v['code']} thành công!", Colors.green);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 🎯 HÀM GỌI API LẤY LINK VÀ MỞ INAPPWEBVIEW VNPay
  // =========================================================================
  Future<void> _processVNPayPayment(int shipmentId, int amount) async {
    try {
      final String paymentApiUrl = "$apiGatewayUrl/shipments/payments/create-url?shipmentId=$shipmentId&amount=$amount";
      final response = await http.get(Uri.parse(paymentApiUrl));
      
      if (response.statusCode == 200) {
        String vnpayUrl = response.body.replaceAll('"', '').trim(); 
        
        if (mounted) {
          final paymentResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VNPayWebViewScreen(initialUrl: vnpayUrl),
            ),
          );

          if (paymentResult == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Thanh toán VNPay thành công!"), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TrackingScreen()),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã hủy thanh toán hoặc giao dịch thất bại."), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        _showSnackBar("Lỗi Backend không trả link thanh toán", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối VNPay: $e", Colors.red);
    }
  }

  // 🚀 HÀM ĐÓNG GÓI TẠO ĐƠN VÀ CHUYỂN VNPay
  Future<void> _handleCreateOrder() async {
    if (pickupAddress == null || deliveryAddress == null) {
      _showSnackBar("Vui lòng thiết lập đầy đủ địa chỉ lấy hàng và giao hàng!", Colors.red);
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

    setState(() => _isLoading = true);

    try {
      String? token = await SessionManager.getToken();
      int? senderId = await SessionManager.getUserId();

      // Khấu trừ tiền thanh toán cuối cùng
      double discountAmt = _selectedVoucher != null ? (_selectedVoucher!['discountAmount'] ?? 0).toDouble() : 0.0;
      double finalFee = _baseShippingFee - discountAmt;
      if (finalFee < 0) finalFee = 0;

      var request = http.MultipartRequest('POST', Uri.parse('$apiGatewayUrl/shipments/'));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (senderId != null) {
        request.headers['X-User-Id'] = senderId.toString();
      }

      request.fields['pickupAddress'] = pickupAddress!;
      request.fields['pickupLatitude'] = pickupLat.toString();
      request.fields['pickupLongitude'] = pickupLng.toString();
      request.fields['deliveryAddress'] = deliveryAddress!;
      request.fields['deliveryLatitude'] = deliveryLat.toString();
      request.fields['deliveryLongitude'] = deliveryLng.toString();
      
      request.fields['packageDescription'] = _packageDescController.text.trim();
      request.fields['shippingFee'] = finalFee.toString(); 

      if (_packageValueController.text.isNotEmpty) {
        request.fields['packageValue'] = _packageValueController.text.trim();
      }
      
      // 🎯 CHÈN MÃ VOUCHER ĐÃ CHỌN LÊN BACKEND
      if (_selectedVoucher != null) {
        request.fields['voucherCode'] = _selectedVoucher!['code'];
      }

      var imageFile = await http.MultipartFile.fromPath('images', _selectedImage!.path);
      request.files.add(imageFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          int newShipmentId = data['id'] ?? data['data']?['id'] ?? 0;
          int shippingCost = data['shippingCost'] ?? data['data']?['shippingCost'] ?? 0;

          _showSnackBar("Tạo đơn thành công! Đang chuyển hướng thanh toán...", Colors.green);

          if (newShipmentId > 0 && shippingCost > 0) {
            await _processVNPayPayment(newShipmentId, shippingCost);
          } else {
            Navigator.pop(context, true);
          }
        } else {
          _showSnackBar("Tạo đơn thất bại từ hệ thống: ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar("Lỗi hệ thống cục bộ: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double discountAmt = _selectedVoucher != null ? (_selectedVoucher!['discountAmount'] ?? 0).toDouble() : 0.0;
    double finalFee = _baseShippingFee - discountAmt;
    if (finalFee < 0) finalFee = 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Tạo đơn hàng mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KHỐI ĐỊA CHỈ MAPBOX ---
                  _buildSectionTitle("Thông tin địa chỉ"),
                  _buildInputCard([
                    _buildAddressSelector(
                      title: pickupAddress ?? "Chọn điểm lấy hàng",
                      icon: Icons.my_location,
                      iconColor: Colors.blue,
                      isPlaceholder: pickupAddress == null,
                      onTap: () => _selectAddress(true),
                    ),
                    const Divider(height: 24),
                    _buildAddressSelector(
                      title: deliveryAddress ?? "Chọn điểm giao hàng",
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      isPlaceholder: deliveryAddress == null,
                      onTap: () => _selectAddress(false),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),

                  // --- KHỐI THÔNG TIN SẢN PHẨM & ẢNH ---
                  _buildSectionTitle("Thông tin gói hàng"),
                  _buildInputCard([
                    _buildTextField(
                      "Mô tả (VD: Quần áo, tài liệu giấy tờ...)",
                      Icons.inventory_2,
                      Colors.orange,
                      _packageDescController,
                    ),
                    const Divider(height: 20),
                    _buildTextField(
                      "Giá trị hàng hóa khai báo (VNĐ)",
                      Icons.attach_money,
                      Colors.green,
                      _packageValueController,
                      keyboardType: TextInputType.number,
                    ),
                    const Divider(height: 20),
                    InkWell(
                      onTap: _pickImage,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt, color: Colors.blueAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedImage == null ? "Tải lên hình ảnh hàng hóa" : "Đã chọn ảnh",
                                style: TextStyle(
                                  color: _selectedImage == null ? Colors.grey : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(_selectedImage!, width: 40, height: 40, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  // ====== KHỐI VOUCHER MỚI (UX CHUẨN SHOPEE) ======
                  const SizedBox(height: 24),
                  _buildSectionTitle("Khuyến mãi hệ thống"),
                  InkWell(
                    onTap: () => _showVoucherSelectionModal(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedVoucher != null ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedVoucher != null ? Colors.green : Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: _selectedVoucher != null ? Colors.green : Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedVoucher != null ? "Đã áp dụng mã:" : "Mã giảm giá",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                Text(
                                  _selectedVoucher != null 
                                      ? "${_selectedVoucher!['code']} (-${AppFormatters.formatCurrency(discountAmt)})" 
                                      : "Bấm để chọn mã giảm giá",
                                  style: TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.bold, 
                                    color: _selectedVoucher != null ? Colors.green.shade700 : Colors.black87
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedVoucher != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedVoucher = null;
                                });
                              },
                            )
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // ====== KHỐI TỔNG TIỀN ======
                  const SizedBox(height: 24),
                  _buildInputCard([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Phí vận chuyển gốc:", style: TextStyle(color: Colors.grey)),
                        Text(AppFormatters.formatCurrency(_baseShippingFee), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (discountAmt > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Khấu trừ Voucher:", style: TextStyle(color: Colors.green)),
                          Text("- ${AppFormatters.formatCurrency(discountAmt)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tổng chi phí cần trả:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(AppFormatters.formatCurrency(finalFee), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 32),
                  
                  // --- NÚT ĐẶT XE & VNPay ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleCreateOrder,
                      child: const Text(
                        "XÁC NHẬN & THANH TOÁN VNPAY",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAddressSelector({required String title, required IconData icon, required Color iconColor, required bool isPlaceholder, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: isPlaceholder ? Colors.grey : Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, Color iconColor, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, color: iconColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// =========================================================================
// 🌐 TRÌNH DUYỆT NHÚNG VNPAY 
// =========================================================================
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
        title: const Text("Thanh toán VNPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false), 
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          if (url != null) {
            String currentUrl = url.toString();
            debugPrint("📍 WebView đang chuyển hướng: $currentUrl");

            if ((currentUrl.contains("vnp_ResponseCode=00") || currentUrl.contains("shipments/payments/vnpay-return")) && !_isHandled) {
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text("Thành công", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Đơn hàng của bạn đã được thanh toán thành công qua cổng VNPay!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext); 
                Navigator.pop(context, true); 
              },
              child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}