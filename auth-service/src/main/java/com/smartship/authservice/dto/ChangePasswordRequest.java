package com.smartship.authservice.dto;

import lombok.Data;

@Data // Nếu bạn dùng Lombok, hoặc tự Generate Getter/Setter nếu không dùng
public class ChangePasswordRequest {
    private String oldPassword;
    private String newPassword;
    private String confirmPassword;
}