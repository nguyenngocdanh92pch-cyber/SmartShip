package com.smartship.userservice.service;

import com.smartship.userservice.dto.UserProfileDTO;
import com.smartship.userservice.entity.TierConfig;
import com.smartship.userservice.entity.UserProfile;
import com.smartship.userservice.repository.TierConfigRepository;
import com.smartship.userservice.repository.UserProfileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class UserProfileService {

    @Autowired
    private UserProfileRepository profileRepository;

    @Autowired // 🚀 Quan trọng: Đã lấy từ Bản 2 để fix lỗi NullPointerException
    private TierConfigRepository configRepository;

    // HÀM LẤY TẤT CẢ HỒ SƠ
    public List<UserProfile> getAllProfiles() {
        return profileRepository.findAll();
    }

    // HÀM LẤY 1 HỒ SƠ
    public UserProfile getProfile(Long userId) {
        return profileRepository.findById(userId).orElse(null);
    }

    // HÀM KÍCH NỔ THĂNG HẠNG: Tính điểm từ tiền cước, tăng đơn & xét hạng tự động
    @Transactional
    public void processOrderCompletion(Long userId, double shippingCost) {
        // 1. Tính điểm: Giao đơn 10,000đ = tích 10 điểm (Tức là chia cho 1000)
        int pointsEarned = (int) (shippingCost / 1000);

        // 2. Kéo dữ liệu khách hàng lên
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Khách hàng với ID: " + userId));

        // 3. Cộng điểm và Tăng tổng số đơn
        profile.setRewardPoints(profile.getRewardPoints() + pointsEarned);
        profile.setTotalOrders(profile.getTotalOrders() + 1);

        // 4. Check Rank tự động: Lôi bảng Luật (Tier Configs) từ DB lên
        List<TierConfig> configs = configRepository.findAll(Sort.by(Sort.Direction.DESC, "minPoints"));
        for (TierConfig config : configs) {
            // Dò từ trên xuống (Diamond -> Platinum -> Gold -> ...), qua mốc nào gán mốc đó
            if (profile.getRewardPoints() >= config.getMinPoints()) {
                profile.setTier(config.getTierName());
                break;
            }
        }

        // 5. Lưu xuống Database
        profileRepository.save(profile);
    }

    // HÀM CỘNG ĐIỂM THỦ CÔNG (Giữ lại từ Bản 1)
    @Transactional
    public void addPoints(Long userId, int points) {
        UserProfile profile = profileRepository.findById(userId).orElseThrow();
        profile.setRewardPoints(profile.getRewardPoints() + points);
        profileRepository.save(profile);
    }

    // HÀM MỚI ĐƯỢC THÊM VÀO ĐỂ SỬA LỖI
    @Transactional
    public UserProfile saveOrUpdateProfile(UserProfile profile) {
        return profileRepository.save(profile);
    }

    @Transactional
    public void addRewardPoints(Long userId, int points) {
        // Tìm Profile của Tài xế dựa vào userId (Tùy theo Entity của bạn dùng findById hay findByUserId)
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hồ sơ của tài xế này"));

        // Lấy điểm hiện tại (nếu trong DB đang null thì gán bằng 0)
        int currentPoints = profile.getRewardPoints() != null ? profile.getRewardPoints() : 0;

        // Cộng thêm điểm thưởng mới
        profile.setRewardPoints(currentPoints + points);

        // Lưu xuống DB
        profileRepository.save(profile);
        System.out.println("🎉 Đã cộng " + points + " điểm cho tài xế ID: " + userId);
    }
}