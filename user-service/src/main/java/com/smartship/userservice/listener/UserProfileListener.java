package com.smartship.userservice.listener;

import com.smartship.userservice.entity.UserProfile;
import com.smartship.userservice.service.UserProfileService;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class UserProfileListener {

    @Autowired
    private UserProfileService profileService;

    // Lắng nghe liên tục trên queue này
    @RabbitListener(queues = "user.profile.create.queue")
    public void receiveProfileCreationRequest(Long userId) {
        System.out.println("Nhận được yêu cầu tạo profile cho User ID: " + userId);

        try {
            // Kiểm tra xem profile đã tồn tại chưa để tránh tạo trùng lặp
            UserProfile existingProfile = profileService.getProfile(userId);
            if (existingProfile == null) {
                UserProfile newProfile = new UserProfile();
                newProfile.setUserId(userId);
                newProfile.setRewardPoints(0);
                // Các trường khác như avatarUrl, address để null mặc định

                profileService.saveOrUpdateProfile(newProfile);
                System.out.println("Tạo profile thành công cho User ID: " + userId);
            }
        } catch (Exception e) {
            // Nếu có lỗi (vd: rớt mạng CSDL), RabbitMQ sẽ tự động retry hoặc đưa vào hàng đợi lỗi (Dead Letter Queue) nếu cấu hình
            System.err.println("Lỗi khi tạo profile: " + e.getMessage());
        }
    }
}