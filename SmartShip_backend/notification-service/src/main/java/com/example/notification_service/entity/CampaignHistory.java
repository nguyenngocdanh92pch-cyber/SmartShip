package com.example.notification_service.entity; // 🚀 Địa chỉ đúng của bạn đây

import jakarta.persistence.*;
import lombok.Data; // Thư viện giúp tạo tự động Getter/Setter
import java.time.LocalDateTime;

@Entity
@Table(name = "campaign_history")
@Data // 👈 Phải có dòng này để hết lỗi setTitle, setBody ở Controller
public class CampaignHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private String body;
    @Column(name = "target_audience")
    private String targetAudience;
    private String status;
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}