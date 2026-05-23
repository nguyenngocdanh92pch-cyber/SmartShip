package com.smartship.authservice.repository;

import com.smartship.authservice.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    // Tự động generate câu lệnh SQL: SELECT * FROM users WHERE phone_number = ?
    Optional<User> findByPhoneNumber(String phoneNumber);
}