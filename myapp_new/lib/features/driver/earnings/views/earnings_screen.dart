import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared_widgets/stat_card.dart';
import '../models/earnings_summary.dart';
import '../../profile/views/profile_screen.dart';
import '../../../../core/utils/session_manager.dart'; // Đã import SessionManager
import '../../../../core/utils/api_config.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  EarningsSummary? currentData;
  String currentPeriod = 'daily';

  // ⚠️ Quan trọng: Đổi thành IP LAN của laptop đang chạy Spring Boot
  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController thủ công để dễ kiểm soát sự kiện đổi tab
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabSelection);

    // Gọi API lần đầu khi vừa vào màn hình
    _fetchEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Lắng nghe sự kiện chuyển Tab
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;

    switch (_tabController.index) {
      case 0:
        currentPeriod = 'daily';
        break;
      case 1:
        currentPeriod = 'weekly';
        break;
      case 2:
        currentPeriod = 'monthly';
        break;
    }
    _fetchEarningsData(); // Gửi request API mới khi đổi tab
  }

  // Hàm gọi API Backend
  Future<void> _fetchEarningsData() async {
    setState(() => isLoading = true);
    try {
      // 🌟 LẤY ID ĐỘNG TỪ SESSION MANAGER 🌟
      int? driverId = await SessionManager.getUserId();

      // Kiểm tra an toàn: Nếu không có ID (chưa đăng nhập), dừng gọi API
      if (driverId == null) {
        debugPrint("Lỗi: Không tìm thấy ID tài xế trong Session!");
        setState(() => isLoading = false);
        return;
      }

      // Gọi API với driverId thực tế của người đang cầm điện thoại
      final response = await http.get(
        Uri.parse(
          '$apiGatewayUrl/shipments/earnings/driver/$driverId?period=$currentPeriod',
        ),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          currentData = EarningsSummary.fromJson(decodedData);
          isLoading = false;
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'SmartShip Driver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.account_circle, size: 30),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Thanh chọn Tab (Daily / Weekly / Monthly)
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Phần nội dung (Xoay Loading hoặc Hiển thị dữ liệu)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentData == null
                  ? const Center(
                      child: Text(
                        "Không có dữ liệu",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện chính sau khi có dữ liệu từ API
  Widget _buildDashboardContent() {
    String title = currentPeriod == 'daily'
        ? 'Daily Earnings'
        : currentPeriod == 'weekly'
        ? 'Weekly Earnings'
        : 'Monthly Earnings';

    return RefreshIndicator(
      onRefresh: _fetchEarningsData, // Kéo xuống để gọi lại API tiền
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), // Cho phép kéo làm mới
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            '\$${currentData!.totalEarnings.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // 🌟 KHU VỰC VẼ BIỂU ĐỒ 🌟
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildBarChart(),
          ),

          const SizedBox(height: 24),

          // Các thẻ thông số bên dưới (Đã gỡ bỏ Expanded và ListView cũ để cuộn mượt hơn)
          StatCard(
            icon: Icons.local_shipping,
            title: 'Total Deliveries',
            value: currentData!.totalDeliveries.toString(),
          ),
          StatCard(
            icon: Icons.access_time,
            title: 'Hours Online',
            value: currentData!.hoursOnline,
          ),
          StatCard(
            icon: Icons.payments,
            title: 'Tips Earned',
            value: '\$${currentData!.tipsEarned.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  // --- HÀM CẤU HÌNH BIỂU ĐỒ CỘT (FL_CHART) ---
  Widget _buildBarChart() {
    if (currentData!.chartData.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có chuyến xe nào",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Tìm giá trị lớn nhất để cấu hình trục Y
    double maxY = currentData!.chartData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 10; // Chống lỗi chia cho 0

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2, // Chừa khoảng trống phía trên đỉnh cột
        barTouchData: BarTouchData(
          enabled: false,
        ), // Tắt hiệu ứng chạm tạm thời
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index < 0 || index >= currentData!.chartData.length) {
                  return const SizedBox.shrink();
                }
                // Vẽ nhãn trục X (VD: 08:00, MONDAY, Ngày 1)
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    currentData!.chartData[index].label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ), // Ẩn số trục Y cho gọn
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false), // Tắt lưới nền
        borderData: FlBorderData(show: false), // Tắt viền xung quanh
        // Render các cột biểu đồ
        barGroups: currentData!.chartData.asMap().entries.map((entry) {
          int index = entry.key;
          double val = entry.value.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ), // Bo góc đỉnh cột
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
