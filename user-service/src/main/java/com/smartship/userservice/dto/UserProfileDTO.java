package com.smartship.userservice.dto;

import lombok.Data; // Nếu bạn dùng thư viện Lombok để tự tạo Getter/Setter

@Data
public class UserProfileDTO {
    private Long userId;
    private String fullName;
    private String avatarUrl;
    private String defaultAddress;
    private String idCardImageUrl;
    private String driverLicenseUrl;
    private String vehicleInfo;
    private Integer rewardPoints;
}