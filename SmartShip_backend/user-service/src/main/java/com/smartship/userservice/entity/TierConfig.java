package com.smartship.userservice.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "tier_configs")
@Getter
@Setter
public class TierConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tier_name", unique = true)
    private String tierName; // BRONZE, SILVER, GOLD, PLATINUM, DIAMOND

    @Column(name = "min_points")
    private Integer minPoints; // Số điểm tối thiểu để đạt hạng này
}