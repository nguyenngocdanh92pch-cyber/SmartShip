class AppConstants {
  // API Endpoints (Thay đổi theo Server của bạn)
  static const String baseUrl = "http://your-api-url.com/api";

  // Trạng thái đơn hàng (Đồng bộ với Backend Spring Boot)
  static const String statusPending = "PENDING";
  static const String statusAccepted = "ACCEPTED";
  static const String statusPickedUp = "PICKED_UP";
  static const String statusAtWarehouse = "AT_WAREHOUSE";
  static const String statusDelivered = "DELIVERED";
  static const String statusCancelled = "CANCELLED";

  // Shared Preferences Keys
  static const String keyToken = "user_token";
  static const String keyRole = "user_role"; // DRIVER hoặc SENDER
}
