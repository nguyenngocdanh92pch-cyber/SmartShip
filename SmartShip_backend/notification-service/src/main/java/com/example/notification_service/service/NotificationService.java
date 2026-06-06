package com.example.notification_service.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.example.notification_service.dto.NotificationRequest;
import com.example.notification_service.entity.NotificationLog;
import com.example.notification_service.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository repository;
    private final RestTemplate restTemplate; // Giữ lại RestTemplate để gọi sang User-Service

    public void sendPushNotification(NotificationRequest request) {
        try {
            // 1. TẠO HỘP THƯ CHUẨN FIREBASE + DÁN MÁC KHẨN CẤP (HIGH PRIORITY)
            Message.Builder messageBuilder = Message.builder()
                    .setNotification(Notification.builder()
                            .setTitle(request.getTitle())
                            .setBody(request.getBody())
                            .build())
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build());

            // Tự động phân loại: Gửi đích danh (Token) hoặc gửi theo nhóm (Topic)
            boolean isTopic = false;
            if (request.getTargetToken() != null && !request.getTargetToken().isEmpty()) {
                messageBuilder.setToken(request.getTargetToken());
            } else if (request.getTopic() != null && !request.getTopic().isEmpty()) {
                messageBuilder.setTopic(request.getTopic());
                isTopic = true;
            } else {
                throw new IllegalArgumentException("Thiếu địa chỉ: Phải có Token hoặc Topic!");
            }

            // 2. NHẤN NÚT GỬI QUA SERVER GOOGLE FIREBASE
            Message message = messageBuilder.build();
            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Đã bắn thông báo Firebase! Phản hồi: " + response);

            // ===============================================================
            // 3. GHI VÀO SỔ XỐ (LOG) - GỘP LOGIC CỦA CẢ 2 BẢN
            // ===============================================================
            if (isTopic) {
                // TRƯỜNG HỢP A: GỬI THEO TOPIC (GỌI SANG USER-SERVICE ĐỂ LẤY ID)
                String userServiceUrl = "http://localhost:8080/users/ids-by-topic?topic=" + request.getTopic();
                try {
                    Long[] realUserIds = restTemplate.getForObject(userServiceUrl, Long[].class);

                    if (realUserIds != null && realUserIds.length > 0) {
                        for (Long userId : realUserIds) {
                            NotificationLog log = NotificationLog.builder()
                                    .userId(userId)
                                    .isRead(false)
                                    .targetToken("TOPIC: " + request.getTopic())
                                    .title(request.getTitle())
                                    .body(request.getBody())
                                    .sentAt(LocalDateTime.now())
                                    .build();
                            repository.save(log);
                        }
                        System.out.println("✅ Đã lưu sổ lịch sử cho " + realUserIds.length + " người dùng trong Topic!");
                    }
                } catch (Exception apiEx) {
                    System.err.println("❌ Lỗi khi gọi sang User Service lấy ID: " + apiEx.getMessage());
                }
            } else {
                // TRƯỜNG HỢP B: GỬI THEO TOKEN CÁ NHÂN (ĐÃ ĐƯỢC SỬA)
                NotificationLog log = NotificationLog.builder()
                        .userId(request.getUserId()) // 🔥 ĐÃ MỞ KHÓA VÀ LƯU USER ID VÀO ĐÂY!
                        .targetToken(request.getTargetToken())
                        .title(request.getTitle())
                        .body(request.getBody())
                        .isRead(false)
                        .sentAt(LocalDateTime.now())
                        .build();

                repository.save(log);
                System.out.println("✅ Đã lưu sổ thông báo cá nhân cho userId: " + request.getUserId() + " thành công!");
            }

        } catch (FirebaseMessagingException | IllegalArgumentException e) {
            System.err.println("Lỗi gửi Firebase: " + e.getMessage());
        }
    }
}