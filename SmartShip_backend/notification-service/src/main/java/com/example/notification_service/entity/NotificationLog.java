package com.example.notification_service.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notification_logs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 🎯 1. BỔ SUNG USER ID ĐỂ BIẾT CỦA AI MÀ ĐẾM CHUÔNG
    @Column(name = "user_id")
    private Long userId;

    // 🎯 2. BỔ SUNG BIẾN NÀY ĐỂ LÀM CHỮ IN ĐẬM/IN NHẠT
    @Column(name = "is_read")
    private boolean isRead = false;

    private String targetToken;
    private String title;
    private String body;

    // Biến này Xuân đang dùng chữ sentAt
    private LocalDateTime sentAt;
}