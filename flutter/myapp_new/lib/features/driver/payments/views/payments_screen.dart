import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/utils/api_config.dart';
import '../../../../core/utils/session_manager.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgDeep = Color(0xFF080D1A);
const _bgCard = Color(0xFF0F1628);
const _bgSurface = Color(0xFF162036);
const _accent = Color(0xFF2D7EFF);
const _accentGlow = Color(0x222D7EFF);
const _green = Color(0xFF00D68F);
const _red = Color(0xFFFF4D6A);
const _textPri = Color(0xFFECF1FF);
const _textSec = Color(0xFF6B7FA8);
const _divider = Color(0xFF1E2C45);
// ───────────────────────────────────────────────────────────────

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

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      int? driverId = await SessionManager.getUserId();
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
      }
    } catch (e) {
      debugPrint("Lỗi tải ví: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _executeWithdrawal() async {
    setState(() => _isLoading = true);
    try {
      int? driverId = await SessionManager.getUserId();
      final response = await http.post(
        Uri.parse("$_apiUrl/shipments/wallet/withdraw"),
        headers: {'X-User-Id': driverId.toString()},
        body: {
          'amount': _currentBalance.toString(),
          'bankInfo': 'Chase Bank **** 1234',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar("Đã gửi yêu cầu rút tiền thành công!", isError: false);
        }
        _fetchWalletData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) _showSnackBar(response.body, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        _showSnackBar("Lỗi kết nối mạng, vui lòng thử lại!", isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleCashOut() {
    if (_currentBalance <= 0) {
      _showSnackBar("Số dư không đủ để rút!", isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.15),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _accent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác nhận rút tiền',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn muốn rút ${_currentBalance.toStringAsFixed(0)} đ\nvề tài khoản Chase Bank?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSec,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSec,
                        side: const BorderSide(color: _divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _executeWithdrawal();
                      },
                      child: const Text(
                        'Rút ngay',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchWalletData,
                      color: _accent,
                      backgroundColor: _bgCard,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          const SizedBox(height: 8),
                          _buildBalanceCard(),
                          const SizedBox(height: 14),
                          _buildCashOutButton(),
                          const SizedBox(height: 28),
                          _buildPayoutMethod(),
                          const SizedBox(height: 28),
                          _buildTransactionSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: _bgCard,
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ví của tôi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPri,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Quản lý thu nhập & thanh toán',
                  style: TextStyle(fontSize: 12, color: _textSec),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchWalletData,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _divider),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _textSec,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance card ─────────────────────────────────────────────
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2557), Color(0xFF0A1A3E)],
        ),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: _textSec,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'Số dư hiện tại',
                style: TextStyle(color: _textSec, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentBalance.toStringAsFixed(0)} đ',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: _textPri,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: _green,
                  size: 13,
                ),
                SizedBox(width: 5),
                Text(
                  'Sẵn sàng rút về tài khoản',
                  style: TextStyle(
                    fontSize: 12,
                    color: _green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cash out button ──────────────────────────────────────────
  Widget _buildCashOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _handleCashOut,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_outward_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              'Rút tiền ngay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payout method ────────────────────────────────────────────
  Widget _buildPayoutMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textPri,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accentGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: _accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chase Bank',
                      style: TextStyle(
                        color: _textPri,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '**** **** **** 1234',
                      style: TextStyle(color: _textSec, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _divider),
                ),
                child: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Transactions ─────────────────────────────────────────────
  Widget _buildTransactionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Lịch sử giao dịch',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                ),
              ),
            ),
            Text(
              '${_transactions.length} giao dịch',
              style: const TextStyle(fontSize: 12, color: _textSec),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgSurface,
                    border: Border.all(color: _divider),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: _textSec,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(color: _textSec, fontSize: 14),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: _divider, height: 1),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final date = DateTime.parse(tx['createdAt']);
                final formatted = DateFormat('dd/MM/yyyy – HH:mm').format(date);
                final amount = (tx['amount'] ?? 0).toDouble();
                final isPositive = amount > 0;
                final amountStr = isPositive
                    ? '+${amount.toStringAsFixed(0)} đ'
                    : '-${amount.abs().toStringAsFixed(0)} đ';

                return _buildTransactionTile(
                  date: formatted,
                  description: tx['description'] ?? 'Giao dịch',
                  amount: amountStr,
                  isPositive: isPositive,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionTile({
    required String date,
    required String description,
    required String amount,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? _green.withValues(alpha: 0.12)
                  : _red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isPositive ? _green : _red,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: _textPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(color: _textSec, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? _green : _red,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
