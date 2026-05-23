package com.example.notification_service.controller;

import com.example.notification_service.dto.NotificationRequest;
import com.example.notification_service.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @PostMapping("/send")
    public String sendNotification(@RequestBody NotificationRequest request) {
        notificationService.sendPushNotification(request);
        return "Đã tiếp nhận lệnh gửi thông báo Firebase!";
    }
}