package com.smartship.authservice.controller;

import com.smartship.authservice.dto.*;
import com.smartship.authservice.entity.User;
import com.smartship.authservice.repository.UserRepository;
import com.smartship.authservice.service.AuthService;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
    public ResponseEntity<String> registerUser(@RequestBody RegisterRequest request) {

        // 1. Tạo Entity mới và map dữ liệu từ Request sang
        User newUser = new User();
        newUser.setFullName(request.getFullName());
        newUser.setPhoneNumber(request.getPhoneNumber());
        newUser.setRole(User.Role.valueOf(request.getRole().toUpperCase()));

        // Mã hóa và gán mật khẩu
        String rawPassword = request.getPassword();
        String encodedPassword = passwordEncoder.encode(rawPassword);
        newUser.setPasswordHash(encodedPassword);

        // 2. Lưu User vào database user_db của auth-service
        User savedUser = userRepository.save(newUser);

        // 3. Đóng gói dữ liệu gửi sang RabbitMQ (user-service)
        Map<String, Object> profileData = new HashMap<>();
        profileData.put("userId", savedUser.getId());
        profileData.put("role", savedUser.getRole().name());

        if ("DRIVER".equalsIgnoreCase(request.getRole())) {
            profileData.put("vehicleInfo", request.getVehicleInfo());
            profileData.put("cccdUrl", request.getCccdUrl());
            profileData.put("licenseUrl", request.getLicenseUrl());
        }

        rabbitTemplate.convertAndSend(PROFILE_QUEUE, profileData);

        System.out.println("Đã gửi yêu cầu tạo profile cho User ID: " + savedUser.getId());

        // 4. Trả về kết quả ngay lập tức cho Frontend/Mobile
        return ResponseEntity.ok("Đăng ký thành công!");
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // Lấy trực tiếp đối tượng AuthResponse đã được xử lý từ tầng Service
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            // Nếu có lỗi (Sai pass, Tài khoản PENDING/LOCKED), ném về lỗi 400 Bad Request
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/update-info/{id}")
    public ResponseEntity<?> updateUserInfo(@PathVariable Long id, @RequestBody UpdateProfileRequest request) {
        try {
            authService.updateUserInfo(id, request.getFullName(), request.getPhone());
            return ResponseEntity.ok("Cập nhật thông tin thành công và đã phát tín hiệu đồng bộ!");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Lỗi: " + e.getMessage());
        }
    }

    @PutMapping("/change-password/{id}")
    public ResponseEntity<?> changePassword(@PathVariable Long id, @RequestBody ChangePasswordRequest request) {
        try {
            authService.changePassword(id, request);
            return ResponseEntity.ok("Đổi mật khẩu thành công!");
        } catch (Exception e) {
            // Nếu sai mật khẩu cũ hoặc không khớp, nó sẽ ném lỗi 400 Bad Request về cho Flutter
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // =========================================================
    // API CẤP TÊN VÀ SĐT CHO FRONTEND (API COMPOSITION)
    // =========================================================
    @GetMapping("/all-users-info")
    public ResponseEntity<List<Map<String, Object>>> getAllUsersInfo() {
        List<User> users = userRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();

        for (User u : users) {
            Map<String, Object> map = new HashMap<>();
            map.put("userId", u.getId());
            map.put("fullName", u.getFullName());
            map.put("phone", u.getPhoneNumber());
            result.add(map);
        }
        return ResponseEntity.ok(result);
    }
}