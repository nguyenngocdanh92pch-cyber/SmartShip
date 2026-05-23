package com.smartship.userservice.controller;

import com.smartship.userservice.entity.TierConfig;
import com.smartship.userservice.repository.TierConfigRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users/admin/tier-configs")
public class TierConfigController {

    @Autowired
    private TierConfigRepository configRepository;

    // Lấy danh sách cấu hình điểm
    @GetMapping
    public ResponseEntity<List<TierConfig>> getAllConfigs() {
        return ResponseEntity.ok(configRepository.findAll());
    }

    // Cập nhật cấu hình điểm từ Web Admin
    @PutMapping("/update")
    public ResponseEntity<String> updateConfigs(@RequestBody List<TierConfig> configs) {
        configRepository.saveAll(configs);
        return ResponseEntity.ok("Cập nhật mốc điểm thành công!");
    }
}