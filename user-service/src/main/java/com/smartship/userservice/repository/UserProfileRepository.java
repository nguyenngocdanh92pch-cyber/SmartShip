package com.smartship.userservice.repository;

import com.smartship.userservice.entity.UserProfile;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {
    // JpaRepository đã cung cấp sẵn các hàm save, findById, delete...
    // VŨ KHÍ QUÉT DIỆN RỘNG: Cập nhật rank cho TOÀN BỘ khách hàng chỉ với 1 câu lệnh
    @Modifying
    @Transactional
    @Query(value = "UPDATE user_profiles SET tier = CASE " +
            "WHEN reward_points >= :diamond THEN 'DIAMOND' " +
            "WHEN reward_points >= :platinum THEN 'PLATINUM' " +
            "WHEN reward_points >= :gold THEN 'GOLD' " +
            "WHEN reward_points >= :silver THEN 'SILVER' " +
            "ELSE 'BRONZE' END", nativeQuery = true)
    void updateAllUserTiers(
            @Param("silver") int silver,
            @Param("gold") int gold,
            @Param("platinum") int platinum,
            @Param("diamond") int diamond
    );
}