package com.smartship.authservice.service;

import com.smartship.authservice.dto.*;
import com.smartship.authservice.entity.User;
import com.smartship.authservice.repository.UserRepository;
import com.smartship.authservice.util.JwtUtil;
import org.springframework.amqp.rabbit.core.RabbitTemplate; // Import RabbitTemplate
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // Import Transactional

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    // Khai báo thêm RabbitTemplate
    private final RabbitTemplate rabbitTemplate;

    // Tên queue phải khớp chính xác với cấu hình bên user-service
    private static final String PROFILE_UPDATE_QUEUE = "user.profile.update.queue";

    // Cập nhật Constructor để Spring tự động Inject RabbitTemplate vào
    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       RabbitTemplate rabbitTemplate) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.rabbitTemplate = rabbitTemplate;
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

    // --- LOGIC MỚI: CẬP NHẬT THÔNG TIN VÀ ĐỒNG BỘ QUA RABBITMQ ---
    @Transactional
    public User updateUserInfo(Long userId, String newFullName, String newPhone) {
        // 1. Cập nhật dữ liệu vào database của auth-service
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với ID: " + userId));

        user.setFullName(newFullName);
        user.setPhoneNumber(newPhone);

        // Lưu vào DB (MySQL/PostgreSQL)
        User savedUser = userRepository.save(user);

        // 2. Bắn sự kiện qua RabbitMQ để user-service đồng bộ dữ liệu
        UserUpdatedEvent event = new UserUpdatedEvent(userId, newFullName, newPhone);
        rabbitTemplate.convertAndSend(PROFILE_UPDATE_QUEUE, event);

        System.out.println("Đã publish sự kiện cập nhật cho User ID: " + userId);

        return savedUser;
    }

    // --- LOGIC MỚI: ĐỔI MẬT KHẨU ---
    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        // 1. Kiểm tra mật khẩu mới và xác nhận mật khẩu có khớp nhau không
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Mật khẩu mới và xác nhận mật khẩu không khớp!");
        }

        // 2. Tìm người dùng trong DB
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với ID: " + userId));

        // 3. Kiểm tra mật khẩu cũ xem có nhập đúng không
        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu cũ không chính xác!");
        }

        // 4. Nếu mọi thứ OK, mã hóa mật khẩu mới và lưu xuống DB
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        System.out.println("Đã đổi mật khẩu thành công cho User ID: " + userId);
    }
}