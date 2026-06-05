class UserProfile {
  int? userId;
  String? fullName;
  String? avatarUrl;
  String? defaultAddress;
  String? idCardImageUrl;
  String? driverLicenseUrl;
  String? vehicleInfo;
  int? rewardPoints;
  String? tier; // 🌟 THÊM TRƯỜNG TIER (Hạng)

  UserProfile({
    this.userId,
    this.fullName,
    this.avatarUrl,
    this.defaultAddress,
    this.idCardImageUrl,
    this.driverLicenseUrl,
    this.vehicleInfo,
    this.rewardPoints,
    this.tier, // 🌟 THÊM VÀO CONSTRUCTOR
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      defaultAddress: json['defaultAddress'],
      idCardImageUrl: json['idCardImageUrl'],
      driverLicenseUrl: json['driverLicenseUrl'],
      vehicleInfo: json['vehicleInfo'],
      rewardPoints: json['rewardPoints'] ?? 0,
      tier: json['tier'], // 🌟 LẤY TIER TỪ JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'defaultAddress': defaultAddress,
      'idCardImageUrl': idCardImageUrl,
      'driverLicenseUrl': driverLicenseUrl,
      'vehicleInfo': vehicleInfo,
      'rewardPoints': rewardPoints,
      'tier': tier, // 🌟 PARSE TIER
    };
  }
}
