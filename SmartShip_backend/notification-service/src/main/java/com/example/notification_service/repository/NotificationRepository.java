package com.example.notification_service.repository;

import com.example.notification_service.entity.NotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<NotificationLog, Long> {

    // Đếm số lượng chưa đọc
    int countByUserIdAndIsReadFalse(Long userId);

    // 🎯 Đã đổi chữ CreatedAt thành SentAt cho khớp với file Entity
    List<NotificationLog> findByUserIdOrderBySentAtDesc(Long userId);
}