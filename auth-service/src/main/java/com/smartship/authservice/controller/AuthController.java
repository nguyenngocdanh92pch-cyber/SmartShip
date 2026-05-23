package com.smartship.authservice.controller;

import com.smartship.authservice.dto.LoginRequest;
import com.smartship.authservice.dto.RegisterRequest;
import com.smartship.authservice.dto.AuthResponse;
import com.smartship.authservice.entity.User;
import com.smartship.authservice.repository.UserRepository;
import com.smartship.authservice.service.AuthService;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RabbitTemplate rabbitTemplate;

    // Khởi tạo bộ mã hóa mật khẩu
    private PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // Tên queue phải khớp với bên user-service
    private static final String PROFILE_QUEUE = "user.profile.create.queue";

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<String> registerUser(@RequestBody RegisterRequest request) { // Sửa thành RegisterRequest

        // 1. Tạo Entity mới và map dữ liệu từ Request (Postman) sang
        User newUser = new User();
        newUser.setFullName(request.getFullName());
        newUser.setPhoneNumber(request.getPhoneNumber());
        newUser.setRole(User.Role.valueOf(request.getRole().toUpperCase()));

        // QUAN TRỌNG: Lấy mật khẩu, mã hóa và gán vào trường passwordHash để không bị lỗi NOT NULL
        String rawPassword = request.getPassword();
        String encodedPassword = passwordEncoder.encode(rawPassword);
        newUser.setPasswordHash(encodedPassword);

        // 2. Lưu User vào database user_db
        User savedUser = userRepository.save(newUser);

        // 3. Gửi userId sang RabbitMQ
        // Thay vì gửi cả object phức tạp, gửi mỗi cái ID (kiểu Long) cho an toàn và nhẹ
        rabbitTemplate.convertAndSend(PROFILE_QUEUE, savedUser.getId());

        System.out.println("Đã gửi yêu cầu tạo profile cho User ID: " + savedUser.getId());

        // 4. Trả về kết quả ngay lập tức cho Frontend/Mobile
        return ResponseEntity.ok("Đăng ký thành công!");
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        // Lấy trực tiếp đối tượng AuthResponse đã được xử lý từ tầng Service
        AuthResponse response = authService.login(request);

        // Trả thẳng đối tượng đó về phía Client (Mobile/Web)
        return ResponseEntity.ok(response);
    }
}