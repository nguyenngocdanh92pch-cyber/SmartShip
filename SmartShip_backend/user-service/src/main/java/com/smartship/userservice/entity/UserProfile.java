package com.smartship.userservice.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*; // Sử dụng cho Spring Boot 3.x
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "user_profiles")
@Getter
@Setter
public class UserProfile {
    @Id
    @Column(name = "user_id")
    private Long userId;

    // UserProfile.java
    @Column(name = "full_name")
    private String fullName;

    @Column(name = "phone")
    private String phone;

    private String avatarUrl;
    private String defaultAddress;
    private String idCardImageUrl;
    private String driverLicenseUrl;

    @Column(name = "id_card_back_url")
    private String idCardBackUrl;

    @Column(name = "vehicle_reg_url")
    private String vehicleRegUrl;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb") // Lưu thông tin xe dạng JSON [cite: 101, 175]
    private String vehicleInfo;

    @Column(name = "reward_points")
    private Integer rewardPoints = 0; // Điểm thưởng mặc định là 0 [cite: 102, 176]

    @Column(name = "total_orders")
    private Integer totalOrders = 0;

    @Column(name = "tier")
    private String tier = "BRONZE";

    @Column(name = "status")
    private String status = "ACTIVE";
}