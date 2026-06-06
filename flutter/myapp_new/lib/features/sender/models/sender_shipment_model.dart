import 'package:flutter/material.dart';

enum SenderShipmentStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

class SenderShipmentModel {
  final String id;
  final String driverId; // 🌟 THÊM BIẾN NÀY ĐỂ LÀM PEER_ID KHI CHAT
  final String driverName; // 🌟 THÊM BIẾN NÀY ĐỂ HIỂN THỊ TÊN TÀI XẾ

  final String pickupAddress;
  final String dropoffAddress;
  final String packageDescription;
  final double shippingFee;
  final SenderShipmentStatus status;
  final String createdAt;

  // 🎯 VỊ TRÍ 1: Khai báo biến totalOrders (Từ code của bồ)
  final int? totalOrders;

  SenderShipmentModel({
    required this.id,
    required this.driverId, // 🌟 THÊM VÀO CONSTRUCTOR
    required this.driverName, // 🌟 THÊM VÀO CONSTRUCTOR
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageDescription,
    required this.shippingFee,
    this.status = SenderShipmentStatus.pending,
    required this.createdAt,
    // 🎯 VỊ TRÍ 2: Thêm vào Constructor
    this.totalOrders,
  });

  // Chuyển đổi JSON từ API sang Object Dart (An toàn tuyệt đối)
  factory SenderShipmentModel.fromJson(Map<String, dynamic> json) {
    return SenderShipmentModel(
      id: json['id']?.toString() ?? '',

      // 🌟 MAP JSON TỪ BACKEND TRẢ VỀ
      driverId:
          json['driverId']?.toString() ?? json['driver_id']?.toString() ?? '',
      driverName: json['driverName'] ?? json['driver_name'] ?? 'Tài xế',

      pickupAddress: json['pickupAddress'] ?? 'Chưa xác định',
      // Linh hoạt kiểm tra các key thường gặp từ backend
      dropoffAddress:
          json['destinationAddress'] ??
          json['dropoffAddress'] ??
          'Chưa xác định',
      packageDescription: json['packageDescription'] ?? '',
      shippingFee:
          double.tryParse(
            json['shippingCost']?.toString() ??
                json['shippingFee']?.toString() ??
                '0',
          ) ??
          0.0,
      status: _parseStatus(json['status']?.toString()),
      createdAt: json['createdAt'] ?? '',
      // 🎯 VỊ TRÍ 3: Hứng dữ liệu số lượng đơn hàng (Từ code của bồ)
      totalOrders: json['totalOrders'] as int? ?? 0,
    );
  }

  // Hàm helper để chuyển chuỗi String từ API thành Enum mà không bị lỗi gạch đỏ
  static SenderShipmentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return SenderShipmentStatus.pending;
      case 'ACCEPTED':
        return SenderShipmentStatus.accepted;
      case 'PICKED_UP':
        return SenderShipmentStatus.pickedUp;
      case 'IN_TRANSIT':
        return SenderShipmentStatus.inTransit;
      case 'DELIVERED':
        return SenderShipmentStatus.delivered;
      case 'CANCELLED':
        return SenderShipmentStatus.cancelled;
      default:
        return SenderShipmentStatus.pending;
    }
  }

  // Lấy văn bản hiển thị trạng thái tiếng Việt
  String get statusText {
    switch (status) {
      case SenderShipmentStatus.pending:
        return "Đang tìm tài xế";
      case SenderShipmentStatus.accepted:
        return "Đã nhận đơn";
      case SenderShipmentStatus.pickedUp:
        return "Đã lấy hàng";
      case SenderShipmentStatus.inTransit:
        return "Đang giao hàng";
      case SenderShipmentStatus.delivered:
        return "Thành công";
      case SenderShipmentStatus.cancelled:
        return "Đã hủy";
    }
  }

  // Lấy màu sắc tương ứng với trạng thái
  Color get statusColor {
    switch (status) {
      case SenderShipmentStatus.pending:
        return Colors.orange;
      case SenderShipmentStatus.accepted:
        return Colors.blue;
      case SenderShipmentStatus.delivered:
        return Colors.green;
      case SenderShipmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blueAccent;
    }
  }
}
