package vn.edu.shipmentservice.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.shipmentservice.entity.SystemSetting;
import vn.edu.shipmentservice.repository.SystemSettingRepository;

import java.math.BigDecimal;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@RequestMapping("/shipments/settings")
public class SystemSettingController {

    private final SystemSettingRepository settingRepository;

    // LẤY TOÀN BỘ CÀI ĐẶT
    @GetMapping
    public ResponseEntity<Map<String, String>> getAllSettings() {
        Map<String, String> settings = settingRepository.findAll().stream()
                .collect(Collectors.toMap(SystemSetting::getKey, SystemSetting::getValue));
        return ResponseEntity.ok(settings);
    }

    // LƯU CÀI ĐẶT (Nhận vào 1 cục JSON từ React và lưu từng dòng)
    @PostMapping
    public ResponseEntity<String> saveSettings(@RequestBody Map<String, String> newSettings) {
        newSettings.forEach((k, v) -> {
            SystemSetting setting = settingRepository.findById(k).orElse(new SystemSetting());
            setting.setKey(k);
            setting.setValue(v);
            settingRepository.save(setting);
        });
        return ResponseEntity.ok("Đã lưu cấu hình hệ thống thành công!");
    }

    @GetMapping("/geofence-check")
    public ResponseEntity<BigDecimal> checkGeofenceSurcharge(@RequestParam double lng, @RequestParam double lat) {
        // Viết một câu SQL native query kiểm tra:
        // ST_Contains(geofence_polygon, ST_SetSRID(ST_Point(lng, lat), 4326))
        // Nếu điểm lấy hàng nằm trong Sân bay Tân Sơn Nhất -> return 15000;
        // Nếu nằm trong Bến xe Miền Đông -> return 10000;
        // Mặc định không nằm trong vùng nào -> return 0;

        return ResponseEntity.ok(BigDecimal.ZERO);
    }

    // Thêm API này để lấy 1 giá trị cấu hình cụ thể dựa vào key
    @GetMapping("/{key}")
    public ResponseEntity<String> getSettingValue(@PathVariable String key) {
        return settingRepository.findById(key)
                .map(setting -> ResponseEntity.ok(setting.getValue()))
                .orElse(ResponseEntity.notFound().build());
    }
}