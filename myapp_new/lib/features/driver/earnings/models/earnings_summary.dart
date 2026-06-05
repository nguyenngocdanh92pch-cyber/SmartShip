class ChartPoint {
  final String label;
  final double value;

  ChartPoint({required this.label, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class EarningsSummary {
  final double totalEarnings;
  final int totalDeliveries;
  final double tipsEarned;
  final String hoursOnline;
  final List<ChartPoint> chartData;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalDeliveries,
    required this.tipsEarned,
    required this.hoursOnline,
    required this.chartData,
  });

  // Chuyển JSON từ Spring Boot thành Object Dart
  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    var list = json['chartData'] as List? ?? [];
    List<ChartPoint> chartList = list
        .map((i) => ChartPoint.fromJson(i))
        .toList();

    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      tipsEarned: (json['tipsEarned'] ?? 0).toDouble(),
      hoursOnline: json['hoursOnline'] ?? '0h 0m',
      chartData: chartList,
    );
  }
}
