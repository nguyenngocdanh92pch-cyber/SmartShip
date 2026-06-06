class ShipmentModel {
  final int id;
  final int senderId; // 🌟 THÊM DÒNG NÀY ĐỂ HỨNG ID TỪ BACKEND
  final String senderName;
  final String driverName;
  final String pickupAddress;
  final double pickupLongitude;
  final double pickupLatitude;
  final String packageDescription;
  final double packageValue;
  final double shippingCost;
  final String status;
  final List<String> imageUrls;

  ShipmentModel({
    required this.id,
    required this.senderId, // 🌟 THÊM VÀO CONSTRUCTOR
    required this.senderName,
    required this.driverName,
    required this.pickupAddress,
    required this.pickupLongitude,
    required this.pickupLatitude,
    required this.packageDescription,
    required this.packageValue,
    required this.shippingCost,
    required this.status,
    required this.imageUrls,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'],
      // 🌟 MAP JSON TỪ BACKEND TRẢ VỀ (Thường SpringBoot sẽ trả về camelCase là 'senderId')
      senderId: json['senderId'] ?? json['sender_id'] ?? 0,
      senderName: json['senderName'] ?? json['sender_name'] ?? 'Khách hàng',
      driverName: json['driverName'] ?? json['driver_name'] ?? 'Tài xế',
      pickupAddress: json['pickupAddress'] ?? 'Chưa rõ',
      pickupLongitude: json['pickupLongitude']?.toDouble() ?? 0.0,
      pickupLatitude: json['pickupLatitude']?.toDouble() ?? 0.0,
      packageDescription: json['packageDescription'] ?? '',
      packageValue: json['packageValue']?.toDouble() ?? 0.0,
      shippingCost: json['shippingCost']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }
}
