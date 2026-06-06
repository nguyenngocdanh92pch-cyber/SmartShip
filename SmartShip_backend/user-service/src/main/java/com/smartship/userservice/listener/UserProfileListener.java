package com.smartship.userservice.listener;

import com.smartship.userservice.config.RabbitMQConfig;
import com.smartship.userservice.dto.UserUpdatedEvent;
import com.smartship.userservice.entity.UserProfile;
import com.smartship.userservice.service.UserProfileService;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class UserProfileListener {

    @Autowired
    private UserProfileService profileService;

    // =========================================================
    // 1. HÀM TẠO PROFILE MỚI (LOGIC NÂNG CAO CỦA BỒ)
    // =========================================================
    @RabbitListener(queues = RabbitMQConfig.PROFILE_QUEUE)
    public void receiveProfileCreationRequest(Map<String, Object> profileData) {
        // 1. Rã đông dữ liệu từ Map gửi sang
        Long userId = Long.valueOf(profileData.get("userId").toString());
        String role = (String) profileData.get("role");

        System.out.println("Nhận được yêu cầu tạo profile cho User ID: " + userId + " | Role: " + role);

        try {
            UserProfile existingProfile = profileService.getProfile(userId);
            if (existingProfile == null) {
                UserProfile newProfile = new UserProfile();
                newProfile.setUserId(userId);
                newProfile.setRewardPoints(0);

                // 2. PHÂN LOẠI TRẠNG THÁI VÀ LƯU THÔNG TIN
                if ("DRIVER".equalsIgnoreCase(role)) {
                    newProfile.setStatus("PENDING"); // 🛑 TÀI XẾ MỚI VÀO PHẢI CHỜ DUYỆT

                    // Lưu các thông tin định danh của tài xế vào db
                    if (profileData.containsKey("cccdUrl")) {
                        newProfile.setIdCardImageUrl((String) profileData.get("cccdUrl"));
                    }
                    if (profileData.containsKey("licenseUrl")) {
                        newProfile.setDriverLicenseUrl((String) profileData.get("licenseUrl"));
                    }
                    if (profileData.containsKey("vehicleInfo")) {
                        newProfile.setVehicleInfo((String) profileData.get("vehicleInfo"));
                    }
                } else {
                    newProfile.setStatus("ACTIVE"); // SENDER thì cho xài luôn
                }

                profileService.saveOrUpdateProfile(newProfile);
                System.out.println("Tạo profile thành công cho User ID: " + userId + " với trạng thái: " + newProfile.getStatus());
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi tạo profile: " + e.getMessage());
        }
    }

    // =========================================================
    // 2. HÀM CẬP NHẬT PROFILE (LOGIC ĐỒNG BỘ CỦA BẠN BỒ)
    // =========================================================
    @RabbitListener(queues = RabbitMQConfig.PROFILE_UPDATE_QUEUE)
    public void receiveProfileUpdateRequest(UserUpdatedEvent event) {
        System.out.println("Nhận yêu cầu CẬP NHẬT profile cho User ID: " + event.getUserId());

        try {
            // Tìm profile hiện tại trong database user-service
            UserProfile existingProfile = profileService.getProfile(event.getUserId());

            if (existingProfile != null) {
                // Ghi đè tên và sđt mới
                existingProfile.setFullName(event.getFullName());
                existingProfile.setPhone(event.getPhone());

                // Lưu lại vào database
                profileService.saveOrUpdateProfile(existingProfile);
                System.out.println("Đã đồng bộ cập nhật thành công cho User ID: " + event.getUserId());
            } else {
                System.err.println("Không tìm thấy profile của User ID: " + event.getUserId() + " để cập nhật!");
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi đồng bộ cập nhật profile: " + e.getMessage());
            // Có thể throw lại Exception để RabbitMQ tự động retry (đẩy lại vào hàng đợi)
            throw e;
        }
    }
}