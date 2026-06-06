package com.example.notification_service.dto;

import lombok.Data;

@Data
public class NotificationRequest {
    private String targetToken; // Dùng khi gửi 1 người (để trống nếu gửi nhóm)
    private String topic;       // Dùng khi gửi nhóm (vd: "ALL_DRIVERS")
    private String title;
    private String body;
    private Long userId; // Thêm dòng này vào trong class NotificationRequest nếu chưa có nha
}