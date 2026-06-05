class VoucherResponse {
  final bool isValid;
  final String message;
  final double? discountAmount;
  final String? code;

  VoucherResponse({
    required this.isValid,
    required this.message,
    this.discountAmount,
    this.code,
  });

  factory VoucherResponse.fromJson(Map<String, dynamic> json) {
    return VoucherResponse(
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? 'Lỗi không xác định',
      discountAmount: json['discountAmount']?.toDouble(),
      code: json['code'],
    );
  }
}
