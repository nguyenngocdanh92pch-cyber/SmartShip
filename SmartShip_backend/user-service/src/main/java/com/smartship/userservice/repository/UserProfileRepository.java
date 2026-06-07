package com.smartship.userservice.repository;

import com.smartship.userservice.entity.UserProfile;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {
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

    // =======================================================
    // CÁC HÀM LẤY DANH SÁCH ID ĐỂ PHỤC VỤ PUSH NOTIFICATION
    // =======================================================

    // 1. Lấy Khách hàng (Ai CHƯA có bằng lái thì là SENDER)
    @Query(value = "SELECT user_id FROM user_profiles WHERE driver_license_url IS NULL OR driver_license_url = ''", nativeQuery = true)
    List<Long> findSenderIds();

    // 2. Lấy Tài xế CHÍNH THỨC (Ai ĐÃ CÓ bằng lái thì mới được nhận thông báo DRIVER)
    @Query(value = "SELECT user_id FROM user_profiles WHERE driver_license_url IS NOT NULL AND driver_license_url != ''", nativeQuery = true)
    List<Long> findDriverIds();

    // 3. Lấy Khách hàng VIP
    @Query(value = "SELECT user_id FROM user_profiles WHERE (driver_license_url IS NULL OR driver_license_url = '') AND tier = 'DIAMOND'", nativeQuery = true)
    List<Long> findVipSenderIds();
}