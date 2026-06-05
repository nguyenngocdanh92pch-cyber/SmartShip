class UserProfile {
  int? userId;
  String? fullName;
  String? phone; 
  String? avatarUrl;
  String? defaultAddress;
  String? idCardImageUrl;
  String? driverLicenseUrl;
  String? vehicleInfo;
  int? rewardPoints;
  String? tier;

  int? totalOrders; 

  UserProfile({
    this.userId,
    this.fullName,
    this.phone, 
    this.avatarUrl,
    this.defaultAddress,
    this.idCardImageUrl,
    this.driverLicenseUrl,
    this.vehicleInfo,
    this.rewardPoints,
    this.tier, 
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      fullName: json['fullName'],
      phone: json['phone'], 
      avatarUrl: json['avatarUrl'],
      defaultAddress: json['defaultAddress'],
      idCardImageUrl: json['idCardImageUrl'],
      driverLicenseUrl: json['driverLicenseUrl'],
      vehicleInfo: json['vehicleInfo'],
      rewardPoints: json['rewardPoints'] ?? 0,
      tier: json['tier'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'defaultAddress': defaultAddress,
      'idCardImageUrl': idCardImageUrl,
      'driverLicenseUrl': driverLicenseUrl,
      'vehicleInfo': vehicleInfo,
      'rewardPoints': rewardPoints,
      'tier': tier, 
    };
  }
}