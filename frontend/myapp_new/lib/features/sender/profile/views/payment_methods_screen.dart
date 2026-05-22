import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  // Biến mở rộng: Sau này khi ráp vào chức năng Thanh toán thật, bạn truyền số tiền vào đây
  final double? orderAmount;
  final String? orderId;

  const PaymentMethodsScreen({super.key, this.orderAmount, this.orderId});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Mặc định chọn Tiền mặt
  String _selectedMethod = 'COD';

  // ==========================================
  // 🌟 CẤU HÌNH NGÂN HÀNG CỦA BẠN TẠI ĐÂY 🌟
  // ==========================================
  final String bankID =
      "VCB"; // Tên viết tắt ngân hàng (VD: VCB, MB, BIDV, TPB...)
  final String accountNo = "0123456789"; // Số tài khoản của bạn
  final String accountName =
      "NGUYEN NGOC DANH"; // Tên chủ tài khoản (Viết hoa, không dấu)

  // Hàm sinh ra link ảnh VietQR
  String _generateVietQRUrl() {
    // Nếu màn hình này được gọi để thanh toán thật, lấy tiền thật. Nếu mở xem chơi thì để demo 50,000đ
    double amount = widget.orderAmount ?? 50000.0;
    String addInfo = widget.orderId != null
        ? "Thanh toan don hang ${widget.orderId}"
        : "Thanh toan SmartShip";

    // Format URL của VietQR.io (compact2 là giao diện có kèm logo Napas)
    return "https://img.vietqr.io/image/$bankID-$accountNo-compact2.png"
        "?amount=${amount.toInt()}"
        "&addInfo=${Uri.encodeComponent(addInfo)}"
        "&accountName=${Uri.encodeComponent(accountName)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Phương thức thanh toán",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Chọn phương thức thanh toán mặc định",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),

            // --- LỰA CHỌN 1: TIỀN MẶT (COD) ---
            _buildPaymentOption(
              value: 'COD',
              title: "Tiền mặt (COD)",
              subtitle: "Thanh toán trực tiếp khi giao/nhận hàng",
              icon: Icons.money,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // --- LỰA CHỌN 2: CHUYỂN KHOẢN (VIETQR) ---
            _buildPaymentOption(
              value: 'VIETQR',
              title: "Chuyển khoản (VietQR)",
              subtitle: "Mở app ngân hàng bất kỳ để quét mã",
              icon: Icons.qr_code_scanner,
              iconColor: Colors.blueAccent,
            ),

            // 🌟 KHU VỰC HIỂN THỊ MÃ QR KHI CHỌN VIETQR 🌟
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _selectedMethod == 'VIETQR' ? 380 : 0,
              curve: Curves.easeInOut,
              child: ClipRRect(
                child: _selectedMethod == 'VIETQR'
                    ? Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Quét mã để thanh toán",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Dùng Image.network để tải thẳng ảnh QR từ API
                            Expanded(
                              child: Image.network(
                                _generateVietQRUrl(),
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text("Không thể tải mã QR"),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
      // Nút Xác nhận ở dưới cùng
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // Trả về phương thức đã chọn cho màn hình trước đó
              Navigator.pop(context, _selectedMethod);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Đã chọn: ${_selectedMethod == 'COD' ? 'Tiền mặt' : 'Chuyển khoản VietQR'}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "XÁC NHẬN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Khung giao diện cho từng phương thức
  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    bool isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
