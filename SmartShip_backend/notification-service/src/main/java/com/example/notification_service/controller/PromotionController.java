package com.example.notification_service.controller;

import com.example.notification_service.entity.CampaignHistory;
import com.example.notification_service.entity.NotificationLog;
import com.example.notification_service.repository.CampaignHistoryRepository;
import com.example.notification_service.repository.NotificationRepository;

import com.google.firebase.messaging.AndroidConfig; // 🎯 THÊM IMPORT NÀY
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/promotions")
public class PromotionController {

    @Autowired
    private CampaignHistoryRepository historyRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private RestTemplate restTemplate;

    @GetMapping("/history")
    public ResponseEntity<List<CampaignHistory>> getHistory() {
        return ResponseEntity.ok(historyRepository.findAllByOrderByCreatedAtDesc());
    }

    @PostMapping("/send")
    public ResponseEntity<String> sendPromotion(@RequestBody Map<String, String> payload) {
        String title = payload.get("title");
        String body = payload.get("body");
        String target = payload.get("target");

        // 1. LƯU LỊCH SỬ XUỐNG DATABASE
        CampaignHistory history = new CampaignHistory();
        history.setTitle(title);
        history.setBody(body);
        history.setTargetAudience(target);
        history.setStatus("Đã gửi");
        historyRepository.save(history);

        // 2. BẮN FIREBASE VÀ LƯU SỔ LOG CHO TỪNG USER
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setNotification(notification)
                    .setTopic(target)
                    // ======================================================
                    // 🎯 DÁN MÁC KHẨN CẤP ĐỂ ANDROID SÁNG MÀN HÌNH BÊN FLUTTER
                    // ======================================================
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Đã bắn thông báo Firebase! Phản hồi: " + response);

            // ===============================================================
            // 🎯 LOGIC GỌI SANG USER-SERVICE LẤY DATA THẬT
            // ===============================================================
            if (target != null && !target.isEmpty()) {
                String userServiceUrl = "http://localhost:8080/users/ids-by-topic?topic=" + target; // Nhớ check lại chỗ này có chữ /api không nha nếu rớt
                try {
                    Long[] realUserIds = restTemplate.getForObject(userServiceUrl, Long[].class);
                    if (realUserIds != null && realUserIds.length > 0) {
                        for (Long userId : realUserIds) {
                            NotificationLog log = NotificationLog.builder()
                                    .userId(userId)
                                    .isRead(false)
                                    .targetToken("TOPIC: " + target)
                                    .title(title)
                                    .body(body)
                                    .sentAt(LocalDateTime.now())
                                    .build();
                            notificationRepository.save(log);
                        }
                        System.out.println("✅ Đã lưu sổ cho " + realUserIds.length + " người dùng thật!");
                    }
                } catch (Exception apiEx) {
                    System.err.println("❌ Lỗi khi gọi sang User Service lấy ID: " + apiEx.getMessage());
                }
            }
            // ===============================================================

            return ResponseEntity.ok("Phát thông báo thành công!");

        } catch (FirebaseMessagingException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Lỗi gửi Firebase: " + e.getMessage());
        }
    }
}