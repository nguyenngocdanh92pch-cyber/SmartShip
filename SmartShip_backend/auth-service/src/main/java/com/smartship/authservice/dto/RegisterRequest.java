package com.smartship.authservice.dto;
import lombok.Data;

@Data
public class RegisterRequest {
    private String phoneNumber;
    private String password;
    private String fullName; // Chỉ dùng khi đăng ký
    private String role;     // Chỉ dùng khi đăng ký
    private String vehicleInfo;
    private String cccdUrl;
    private String licenseUrl;
}