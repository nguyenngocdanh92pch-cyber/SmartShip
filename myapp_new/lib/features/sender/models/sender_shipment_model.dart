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
  final String driverId; // 🌟 Dùng để làm PEER_ID khi chat
  final String driverName; // 🌟 Dùng để hiển thị tên tài xế

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
    required this.driverId,
    required this.driverName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageDescription,
    required this.shippingFee,
    this.status = SenderShipmentStatus.pending,
    required this.createdAt,
    // 🎯 VỊ TRÍ 2: Thêm vào Constructor
    this.totalOrders,
  });

  // 🌟 Chuyển đổi JSON từ API sang Object Dart (An toàn tuyệt đối từ bản của bạn bồ)
  factory SenderShipmentModel.fromJson(Map<String, dynamic> json) {
    return SenderShipmentModel(
      // Ép kiểu an toàn, nếu null thì gán chuỗi rỗng
      id: json['id']?.toString() ?? '',

      // Tài xế thường sẽ null khi đơn mới tạo -> Gán text mặc định
      driverId:
          json['driverId']?.toString() ?? json['driver_id']?.toString() ?? '',
      driverName:
          json['driverName']?.toString() ??
          json['driver_name']?.toString() ??
          'Đang chờ tài xế nhận...',

      // Xử lý an toàn cho các trường địa chỉ (Gộp cả logic destinationAddress của bồ)
      pickupAddress:
          json['pickupAddress']?.toString() ?? 'Đang cập nhật địa chỉ...',
      dropoffAddress:
          json['destinationAddress']?.toString() ??
          json['dropoffAddress']?.toString() ??
          'Đang cập nhật địa chỉ...',
          
      packageDescription:
          json['packageDescription']?.toString() ?? 'Không có mô tả',

      // Xử lý an toàn cho tiền phí (đảm bảo luôn ra số double)
      shippingFee:
          double.tryParse(
            json['shippingCost']?.toString() ??
                json['shippingFee']?.toString() ??
                '0',
          ) ??
          0.0,

      // Parse trạng thái từ chuỗi backend
      status: _parseStatus(json['status']?.toString()),

      createdAt: json['createdAt']?.toString() ?? '',

      // 🎯 VỊ TRÍ 3: Hứng dữ liệu số lượng đơn hàng (Từ code của bồ)
      totalOrders: json['totalOrders'] as int? ?? 0,
    );
  }

  // Hàm phụ trợ parse trạng thái từ backend trả về
  static SenderShipmentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return SenderShipmentStatus.pending;
      case 'ACCEPTED':
        return SenderShipmentStatus.accepted;
      case 'PICKED_UP':
        return SenderShipmentStatus.pickedUp;
      case 'IN_TRANSIT':
      case 'DELIVERING': // Bổ sung thêm case này phòng khi backend dùng từ khác (Từ code bạn bồ)
        return SenderShipmentStatus.inTransit;
      case 'DELIVERED':
        return SenderShipmentStatus.delivered;
      case 'CANCELLED':
        return SenderShipmentStatus.cancelled;
      default:
        return SenderShipmentStatus.pending;
    }
  }

  // Lấy văn bản hiển thị trạng thái tiếng Việt cho UI
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

  // Lấy màu sắc tương ứng với trạng thái cho UI (Đã update thêm màu của bạn bồ)
  Color get statusColor {
    switch (status) {
      case SenderShipmentStatus.pending:
        return Colors.orange;
      case SenderShipmentStatus.accepted:
        return Colors.blue;
      case SenderShipmentStatus.pickedUp:
        return Colors.indigo; // Màu mới
      case SenderShipmentStatus.inTransit:
        return Colors.purple; // Màu mới
      case SenderShipmentStatus.delivered:
        return Colors.green;
      case SenderShipmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}