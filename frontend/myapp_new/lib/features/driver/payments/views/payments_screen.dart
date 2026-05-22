import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/utils/session_manager.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _isLoading = true;
  double _currentBalance = 0.0;
  List<dynamic> _transactions = [];
  final String _apiUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // Lấy dữ liệu Ví từ Backend
  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      int? driverId = await SessionManager.getUserId();
      // Đảm bảo có prefix /shipments để không bị API Gateway chặn
      final response = await http.get(
        Uri.parse("$_apiUrl/shipments/wallet/my-wallet"),
        headers: {'X-User-Id': driverId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _currentBalance = (data['balance'] ?? 0).toDouble();
          _transactions = data['transactions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint("Lỗi tải ví: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi tải ví: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🌟 HÀM MỚI: GỌI API RÚT TIỀN THỰC TẾ
  Future<void> _executeWithdrawal() async {
    setState(() => _isLoading = true); // Hiện vòng xoay loading
    try {
      int? driverId = await SessionManager.getUserId();

      final response = await http.post(
        Uri.parse("$_apiUrl/shipments/wallet/withdraw"),
        headers: {'X-User-Id': driverId.toString()},
        body: {
          'amount': _currentBalance.toString(),
          'bankInfo': 'Chase Bank **** 1234', // Gửi kèm thông tin ngân hàng
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã gửi yêu cầu rút tiền thành công!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Rút thành công thì tự động load lại dữ liệu Ví (số dư sẽ về 0)
        _fetchWalletData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.body,
              ), // Hiển thị lỗi từ backend (VD: Số dư không đủ)
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi rút tiền: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi kết nối mạng, vui lòng thử lại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bắt sự kiện bấm nút Cash Out
  void _handleCashOut() {
    if (_currentBalance <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Số dư không đủ để rút!")));
      return;
    }

    // Hiển thị hộp thoại xác nhận rút tiền
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận rút tiền"),
        content: Text(
          "Bạn muốn rút \$${_currentBalance.toStringAsFixed(2)} về tài khoản Chase Bank?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog trước
              _executeWithdrawal(); // Gọi API xử lý rút tiền
            },
            child: const Text("Rút ngay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Payments & Earnings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Current Balance",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${_currentBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Available for Cash Out",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cash Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047AB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleCashOut,
                      child: const Text(
                        "Cash Out Now ↗",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Payout Methods
                  const Text(
                    "Payout Methods",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Chase Bank",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "**** 1234",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          label: const Text(
                            "Add/Edit",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. Transactions List
                  const Text(
                    "Transactions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _transactions.isEmpty
                        ? const Center(
                            child: Text(
                              "Chưa có giao dịch nào",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              var tx = _transactions[index];

                              // Format thời gian
                              DateTime date = DateTime.parse(tx['createdAt']);
                              String formattedDate = DateFormat(
                                'MMM dd, yyyy - HH:mm',
                              ).format(date);

                              // Check tiền âm hay dương để set màu (Rút tiền là số âm)
                              double amount = (tx['amount'] ?? 0).toDouble();
                              bool isPositive = amount > 0;
                              String amountStr = isPositive
                                  ? "+\$${amount.toStringAsFixed(2)}"
                                  : "-\$${amount.abs().toStringAsFixed(2)}";

                              return _buildTransactionItem(
                                formattedDate,
                                tx['description'] ?? 'Giao dịch',
                                amountStr,
                                isPositive ? Colors.green : Colors.red,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionItem(
    String date,
    String description,
    String amount,
    Color amountColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
