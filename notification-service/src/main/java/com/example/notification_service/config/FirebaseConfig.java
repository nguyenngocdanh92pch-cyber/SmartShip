package com.example.notification_service.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct; // Lưu ý: Spring Boot 3 dùng jakarta thay vì javax
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void init() {
        try {
            // Đọc file khóa cấu hình từ thư mục resources
            InputStream serviceAccount = this.getClass().getClassLoader().getResourceAsStream("firebase-config.json");

            if (serviceAccount == null) {
                System.out.println("CẢNH BÁO: Chưa tìm thấy file firebase-config.json trong thư mục resources!");
                return;
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Khởi tạo Firebase thành công!");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}