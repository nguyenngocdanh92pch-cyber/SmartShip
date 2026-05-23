package com.example.notification_service.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.example.notification_service.dto.NotificationRequest;
import com.example.notification_service.entity.NotificationLog;
import com.example.notification_service.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository repository;

    public void sendPushNotification(NotificationRequest request) {
        try {
            // 1. Tạo hộp thư theo chuẩn của Firebase
            Message message = Message.builder()
                    .setToken(request.getTargetToken())
                    .setNotification(Notification.builder()
                            .setTitle(request.getTitle())
                            .setBody(request.getBody())
                            .build())
                    .build();

            // 2. Nhấn nút "Gửi" qua server Google Firebase
            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Đã bắn thông báo thành công! Mã phản hồi từ Google: " + response);

            // 3. Ghi vào sổ xố (PostgreSQL) để sếp kiểm tra
            NotificationLog log = NotificationLog.builder()
                    .targetToken(request.getTargetToken())
                    .title(request.getTitle())
                    .body(request.getBody())
                    .sentAt(LocalDateTime.now())
                    .build();
            repository.save(log);

        } catch (FirebaseMessagingException e) {
            System.err.println("Lỗi cmnr khi gửi Firebase: " + e.getMessage());
        }
    }
}