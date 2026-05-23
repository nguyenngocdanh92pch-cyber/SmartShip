package com.smartship.authservice.service;

import com.smartship.authservice.dto.LoginRequest;
import com.smartship.authservice.dto.RegisterRequest;
import com.smartship.authservice.dto.AuthResponse;
import com.smartship.authservice.entity.User;
import com.smartship.authservice.repository.UserRepository;
import com.smartship.authservice.util.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    // Nhận RegisterRequest có đầy đủ 4 trường
    public void register(RegisterRequest request) {
        User user = new User();
        user.setPhoneNumber(request.getPhoneNumber());
        // Nhớ mã hóa password trước khi lưu vào DB nhé
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName());
        user.setRole(User.Role.valueOf(request.getRole().toUpperCase()));

        userRepository.save(user);
    }

    // Chỉ nhận LoginRequest có 2 trường
    public AuthResponse login(LoginRequest request) {
        // 1. Tìm user theo số điện thoại
        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy tài khoản"));

        // 2. Kiểm tra mật khẩu
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Sai mật khẩu");
        }

        // 3. Sinh JWT Token có chứa thông tin Role
        String token = jwtUtil.generateToken(user.getPhoneNumber(), user.getRole().name());

        // 4. Trả về DTO chứa token và role cho phía Client phân luồng
        AuthResponse response = new AuthResponse();
        response.setToken(token);
        response.setRole(user.getRole().name());
        response.setMessage("Đăng nhập thành công!");
        response.setId(user.getId());

        // 🌟 THÊM DÒNG NÀY ĐỂ GỬI TÊN VỀ CHO APP FLUTTER
        response.setFullName(user.getFullName());
        response.setPhoneNumber(user.getPhoneNumber());

        return response;
    }
}