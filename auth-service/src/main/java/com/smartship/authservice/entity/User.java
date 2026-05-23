package com.smartship.authservice.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // [cite: 163]

    @Column(name = "phone_number", unique = true, nullable = false)
    private String phoneNumber; // [cite: 164]

    @Column(name = "password_hash", nullable = false)
    private String passwordHash; // [cite: 165]

    @Column(name = "full_name")
    private String fullName; // [cite: 166]

    @Enumerated(EnumType.STRING)
    private Role role; // [cite: 167]

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now(); // [cite: 168]

    public enum Role { SENDER, DRIVER }
}