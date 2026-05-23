package com.example.notification_service.dto;

import lombok.Data;

@Data
public class NotificationRequest {
    private String targetToken; // Mã định danh điện thoại của người nhận
    private String title;       // Tiêu đề thông báo
    private String body;        // Nội dung chi tiết
}