import 'package:flutter/material.dart';

class UserStatsCard extends StatelessWidget {
  final String tierName;
  final int rewardPoints;
  final int totalOrders;

  const UserStatsCard({
    super.key,
    required this.tierName,
    required this.rewardPoints,
    required this.totalOrders,
  });

  // Đổi màu chữ theo Rank cho ngầu
  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'DIAMOND': return const Color(0xFF3182CE);
      case 'PLATINUM': return const Color(0xFF475569);
      case 'GOLD': return const Color(0xFFD69E2E);
      case 'SILVER': return const Color(0xFF718096);
      default: return const Color(0xFFC05621); // BRONZE
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cột 1: Hạng
          _buildColumn('Hạng hiện tại', tierName, valueColor: _getTierColor(tierName)),
          _buildDivider(),
          // Cột 2: Điểm
          _buildColumn('Điểm thưởng', '$rewardPoints pt', valueColor: const Color(0xFFE53E3E)),
          _buildDivider(),
          // Cột 3: Tổng đơn
          _buildColumn('Tổng đơn', '$totalOrders'),
        ],
      ),
    );
  }

  Widget _buildColumn(String label, String value, {Color? valueColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            color: valueColor ?? Colors.black87
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade300);
  }
}