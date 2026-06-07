import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models/earnings_summary.dart';
import '../../profile/views/profile_screen.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/api_config.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgDeep = Color(0xFF080D1A); // page background
const _bgCard = Color(0xFF0F1628); // card background
const _bgSurface = Color(0xFF162036); // elevated surface
const _accent = Color(0xFF2D7EFF); // primary blue
const _accentGlow = Color(0x332D7EFF); // blue glow (20%)
const _accentSoft = Color(0xFF3D8BFF); // lighter blue
const _green = Color(0xFF00D68F); // positive / earnings
const _textPri = Color(0xFFECF1FF); // primary text
const _textSec = Color(0xFF6B7FA8); // secondary text
const _divider = Color(0xFF1E2C45); // subtle dividers
// ───────────────────────────────────────────────────────────────

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

  final String apiGatewayUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabSelection);
    _fetchEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    setState(() => isLoading = true);
    try {
      int? driverId = await SessionManager.getUserId();
      if (driverId == null) {
        debugPrint("Lỗi: Không tìm thấy ID tài xế trong Session!");
        setState(() => isLoading = false);
        return;
      }

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
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 2,
                      ),
                    )
                  : currentData == null
                  ? _buildEmptyState()
                  : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          // App name + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SmartShip',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPri,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _accentGlow,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _accent.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'DRIVER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Thu nhập của bạn',
                style: TextStyle(fontSize: 12, color: _textSec),
              ),
            ],
          ),
          const Spacer(),
          // Notification + Avatar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bgSurface,
                border: Border.all(color: _divider, width: 1.5),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _textPri,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: _textSec,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Tuần này'),
            Tab(text: 'Tháng này'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: _divider),
            ),
            child: const Icon(Icons.inbox_rounded, color: _textSec, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: _textSec, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Dashboard content ────────────────────────────────────────
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _fetchEarningsData,
      color: _accent,
      backgroundColor: _bgCard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildEarningsHero(),
          const SizedBox(height: 20),
          _buildChartCard(),
          const SizedBox(height: 20),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  // ── Hero earnings number ─────────────────────────────────────
  Widget _buildEarningsHero() {
    final label = currentPeriod == 'daily'
        ? 'Thu nhập hôm nay'
        : currentPeriod == 'weekly'
        ? 'Thu nhập tuần này'
        : 'Thu nhập tháng này';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1628), Color(0xFF0C1220)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded, color: _green, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSec,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currentData!.totalEarnings.toStringAsFixed(0)} đ',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: _textPri,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded, color: _green, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${currentData!.totalDeliveries} chuyến hoàn thành',
                  style: const TextStyle(
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

  // ── Chart card ───────────────────────────────────────────────
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Biểu đồ thu nhập',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPri,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent,
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Thu nhập (USD)',
                style: TextStyle(fontSize: 11, color: _textSec),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 180, child: _buildBarChart()),
        ],
      ),
    );
  }

  // ── Stats grid ───────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                icon: Icons.local_shipping_rounded,
                iconColor: _accent,
                iconBg: _accentGlow,
                label: 'Tổng chuyến',
                value: currentData!.totalDeliveries.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFFFFB547),
                iconBg: const Color(0x33FFB547),
                label: 'Giờ hoạt động',
                value: currentData!.hoursOnline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatTile(
          icon: Icons.payments_rounded,
          iconColor: _green,
          iconBg: _green.withValues(alpha: 0.15),
          label: 'Tiền tip nhận được',
          value: '${currentData!.tipsEarned.toStringAsFixed(0)} đ',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _textSec),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart ────────────────────────────────────────────────
  Widget _buildBarChart() {
    if (currentData!.chartData.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có chuyến xe nào',
          style: TextStyle(color: _textSec, fontSize: 13),
        ),
      );
    }

    double maxY = currentData!.chartData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _bgSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} đ',
                const TextStyle(
                  color: _textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index < 0 || index >= currentData!.chartData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    currentData!.chartData[index].label,
                    style: const TextStyle(
                      color: _textSec,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: _divider, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: currentData!.chartData.asMap().entries.map((entry) {
          int index = entry.key;
          double val = entry.value.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_accent, _accentSoft],
                ),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY * 1.25,
                  color: _bgSurface,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
