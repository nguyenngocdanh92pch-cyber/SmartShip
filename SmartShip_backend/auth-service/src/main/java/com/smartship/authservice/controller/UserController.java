package com.smartship.authservice.controller;

import com.smartship.authservice.dto.UserAuthResponse;
import com.smartship.authservice.entity.User;
import com.smartship.authservice.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    // API này sẽ khớp với FeignClient bên Shipment Service: GET /users/{id}/profile
    @GetMapping("/{id}/profile")
    public ResponseEntity<UserAuthResponse> getUserProfile(@PathVariable("id") Long id) {

        // Tìm User trong database dựa vào ID
        Optional<User> userOptional = userRepository.findById(id);

        if (userOptional.isPresent()) {
            User user = userOptional.get();
            // Lấy fullName từ Entity và đóng gói vào DTO
            UserAuthResponse response = new UserAuthResponse(user.getId(), user.getFullName());
            return ResponseEntity.ok(response);
        } else {
            // Trả về lỗi 404 Not Found nếu không tìm thấy User
            return ResponseEntity.notFound().build();
        }
    }
}