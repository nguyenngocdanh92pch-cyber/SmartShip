import 'package:flutter/material.dart';

// Định nghĩa các trạng thái của đơn hàng trong quy trình giao
enum OrderPickupStatus {
  upcoming, // Sẽ đến lấy (đang chờ)
  arriving, // Điểm dừng tiếp theo
  pickedUp, // Đã lấy hàng thành công
}

class OrderModel {
  final int id;
  final String orderId;
  final String pickupAddress;
  final String packageDescription;
  final double shippingCost;
  final Offset mapPosition; // Tọa độ giả lập trên Canvas (x, y)
  OrderPickupStatus status; // Trạng thái hiện tại

  OrderModel({
    required this.id,
    required this.orderId,
    required this.pickupAddress,
    required this.packageDescription,
    required this.shippingCost,
    required this.mapPosition,
    this.status = OrderPickupStatus.upcoming, // Mặc định là 'Sẽ đến'
  });
}
