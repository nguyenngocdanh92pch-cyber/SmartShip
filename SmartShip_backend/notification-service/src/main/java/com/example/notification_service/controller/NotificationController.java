package com.example.notification_service.controller;

import com.example.notification_service.dto.NotificationRequest;
import com.example.notification_service.service.NotificationService;
import com.example.notification_service.repository.NotificationRepository;
import com.example.notification_service.entity.NotificationLog;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final NotificationRepository notificationRepository;

    // ==========================================
    // 1. API CHO ADMIN WEB (Gửi thông báo)
    // ==========================================

    @PostMapping("/send")
    public String sendNotification(@RequestBody NotificationRequest request) {
        notificationService.sendPushNotification(request);
        return "Đã tiếp nhận lệnh gửi thông báo Firebase!";
    }

    // ==========================================
    // 2. API CHO MOBILE APP (Làm chuông đỏ + In đậm)
    // ==========================================

    // API A: Đếm số chấm đỏ (Số thông báo chưa đọc)
    @GetMapping("/unread-count/{userId}")
    public ResponseEntity<Integer> getUnreadCount(@PathVariable Long userId) {
        int count = notificationRepository.countByUserIdAndIsReadFalse(userId);
        return ResponseEntity.ok(count);
    }

    // API B: Lấy danh sách thông báo để in ra màn hình
    @GetMapping("/me/{userId}")
    public ResponseEntity<List<NotificationLog>> getMyNotifications(@PathVariable Long userId) {
        // 🎯 Đã gọi đúng tên hàm SentAt
        List<NotificationLog> list = notificationRepository.findByUserIdOrderBySentAtDesc(userId);
        return ResponseEntity.ok(list);
    }

    // API C: Đánh dấu "Đã đọc" khi bấm vào thông báo
    @PutMapping("/{logId}/read")
    public ResponseEntity<String> markAsRead(@PathVariable Long logId) {
        NotificationLog log = notificationRepository.findById(logId).orElse(null);
        if (log != null) {
            // 🎯 BÂY GIỜ GỌI HÀM setRead NÓ SẼ XANH RỜN! VÌ ENTITY ĐÃ CÓ BIẾN isRead
            log.setRead(true);
            notificationRepository.save(log);
        }
        return ResponseEntity.ok("Đã đánh dấu đọc");
    }
}