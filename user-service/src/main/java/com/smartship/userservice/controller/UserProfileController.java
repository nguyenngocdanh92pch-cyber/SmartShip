package com.smartship.userservice.controller;

import com.smartship.userservice.entity.UserProfile;
import com.smartship.userservice.repository.UserProfileRepository;
import com.smartship.userservice.service.GcsService;
import com.smartship.userservice.service.UserProfileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/users")
public class UserProfileController {

    @Autowired
    private UserProfileService profileService;

    @Autowired
    private GcsService gcsService;

    @Autowired
    private UserProfileRepository userProfileRepository;

    // API 1: Chuyên dùng để Upload ảnh lên Google Cloud
    @PostMapping(value = "/upload-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<String> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("Vui lòng chọn một file ảnh!");
            }
            // Gọi Service để ném file lên Cloud
            String publicUrl = gcsService.uploadFile(file);

            // Trả về cái Link cho Mobile App
            return ResponseEntity.ok(publicUrl);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Lỗi khi upload ảnh lên Cloud: " + e.getMessage());
        }
    }

    // API 2: Cập nhật hồ sơ (VẪN GIỮ NGUYÊN NHƯ CŨ)
    // Mobile App sau khi gọi API 1 có được URL, sẽ nhét URL đó vào file JSON rồi gọi API 2 này
    @PutMapping("/me")
    public ResponseEntity<String> updateProfile(@RequestBody UserProfile profile) {
        profileService.saveOrUpdateProfile(profile);
        return ResponseEntity.ok("Cập nhật hồ sơ thành công!");
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfile> getCurrentUserProfile(@RequestParam Long userId) {
        UserProfile profile = profileService.getProfile(userId);

        if (profile != null) {
            return ResponseEntity.ok(profile);
        } else {
            return ResponseEntity.notFound().build(); // Trả về 404 nếu không tìm thấy user
        }
    }

    @GetMapping("/customers")
    public ResponseEntity<List<UserProfile>> getAllCustomers() {
        List<UserProfile> allProfiles = profileService.getAllProfiles();
        List<UserProfile> customers = allProfiles.stream()
                .filter(p -> p.getDriverLicenseUrl() == null || p.getDriverLicenseUrl().isEmpty())
                .toList();
        return ResponseEntity.ok(customers);
    }


    @GetMapping("/dashboard-stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();
        List<UserProfile> allProfiles = profileService.getAllProfiles();

        if (allProfiles != null) {
            long activeDriversCount = allProfiles.stream()
                    .filter(p -> p.getDriverLicenseUrl() != null && !p.getDriverLicenseUrl().isEmpty())
                    .filter(p -> "ACTIVE".equalsIgnoreCase(p.getStatus()))
                    .count();

            long totalCustomersCount = allProfiles.stream()
                    .filter(p -> p.getDriverLicenseUrl() == null || p.getDriverLicenseUrl().isEmpty())
                    .count();

            stats.put("activeDrivers", activeDriversCount);
            stats.put("totalCustomers", totalCustomersCount);
        } else {
            stats.put("activeDrivers", 0L);
            stats.put("totalCustomers", 0L);
        }
        return ResponseEntity.ok(stats);
    }

    /**
     * API 6: Lấy danh sách tài xế
     */
    @GetMapping("/drivers")
    public ResponseEntity<List<UserProfile>> getAllDrivers() {
        List<UserProfile> allProfiles = profileService.getAllProfiles();
        List<UserProfile> drivers = allProfiles.stream()
                .filter(p -> p.getDriverLicenseUrl() != null && !p.getDriverLicenseUrl().isEmpty())
                .toList();
        return ResponseEntity.ok(drivers);
    }

    /**
     * API 7: Cập nhật cấu hình Thăng hạng & Quét toàn bộ Khách hàng
     */
    // ĐÃ SỬA ĐƯỜNG DẪN Ở ĐÂY ĐỂ KHÔNG BỊ ĐỤNG HÀNG NỮA
    @PutMapping("/admin/tiers/apply-mass-update")
    public ResponseEntity<?> updateTiersAndApplyToAll(@RequestBody List<Map<String, Object>> tierConfigs) {

        int silver = 1000, gold = 5000, platinum = 20000, diamond = 50000;

        for (Map<String, Object> config : tierConfigs) {
            String tierName = (String) config.get("tierName");
            int minPoints = Integer.parseInt(config.get("minPoints").toString());

            switch (tierName) {
                case "SILVER": silver = minPoints; break;
                case "GOLD": gold = minPoints; break;
                case "PLATINUM": platinum = minPoints; break;
                case "DIAMOND": diamond = minPoints; break;
            }
        }

        userProfileRepository.updateAllUserTiers(silver, gold, platinum, diamond);
        return ResponseEntity.ok("Cập nhật quy tắc và làm mới thứ hạng toàn hệ thống thành công!");
    }

    // API nhận lệnh cộng điểm từ Shipment Service sang
    @PostMapping("/{userId}/add-points")
    public ResponseEntity<String> addPointsToDriver(
            @PathVariable Long userId,
            @RequestParam int points) {

        // Gọi hàm Service vừa viết ở Bước 1
        profileService.addRewardPoints(userId, points);

        return ResponseEntity.ok("Đã cộng điểm thành công");
    }
}