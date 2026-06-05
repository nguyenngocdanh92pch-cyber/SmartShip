import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  // Bi?n m? r?ng: Sau này khi ráp vào ch?c nang Thanh toán th?t, b?n truy?n s? ti?n vào dây
  final double? orderAmount;
  final String? orderId;

  const PaymentMethodsScreen({super.key, this.orderAmount, this.orderId});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // M?c d?nh ch?n Ti?n m?t
  String _selectedMethod = 'COD';

  // ==========================================
  // ?? C?U HÌNH NGÂN HÀNG C?A B?N T?I ÐÂY ??
  // ==========================================
  final String bankID =
      "VCB"; // Tên vi?t t?t ngân hàng (VD: VCB, MB, BIDV, TPB...)
  final String accountNo = "0123456789"; // S? tài kho?n c?a b?n
  final String accountName =
      "NGUYEN NGOC DANH"; // Tên ch? tài kho?n (Vi?t hoa, không d?u)

  // Hàm sinh ra link ?nh VietQR
  String _generateVietQRUrl() {
    // N?u màn hình này du?c g?i d? thanh toán th?t, l?y ti?n th?t. N?u m? xem choi thì d? demo 50,000d
    double amount = widget.orderAmount ?? 50000.0;
    String addInfo = widget.orderId != null
        ? "Thanh toan don hang ${widget.orderId}"
        : "Thanh toan SmartShip";

    // Format URL c?a VietQR.io (compact2 là giao di?n có kèm logo Napas)
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
          "Phuong th?c thanh toán",
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
                "Ch?n phuong th?c thanh toán m?c d?nh",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),

            // --- L?A CH?N 1: TI?N M?T (COD) ---
            _buildPaymentOption(
              value: 'COD',
              title: "Ti?n m?t (COD)",
              subtitle: "Thanh toán tr?c ti?p khi giao/nh?n hàng",
              icon: Icons.money,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // --- L?A CH?N 2: CHUY?N KHO?N (VIETQR) ---
            _buildPaymentOption(
              value: 'VIETQR',
              title: "Chuy?n kho?n (VietQR)",
              subtitle: "M? app ngân hàng b?t k? d? quét mã",
              icon: Icons.qr_code_scanner,
              iconColor: Colors.blueAccent,
            ),

            // ?? KHU V?C HI?N TH? MÃ QR KHI CH?N VIETQR ??
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
                              "Quét mã d? thanh toán",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Dùng Image.network d? t?i th?ng ?nh QR t? API
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
                                    child: Text("Không th? t?i mã QR"),
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
      // Nút Xác nh?n ? du?i cùng
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
              // Tr? v? phuong th?c dã ch?n cho màn hình tru?c dó
              Navigator.pop(context, _selectedMethod);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Ðã ch?n: ${_selectedMethod == 'COD' ? 'Ti?n m?t' : 'Chuy?n kho?n VietQR'}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "XÁC NH?N",
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

  // Khung giao di?n cho t?ng phuong th?c
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
