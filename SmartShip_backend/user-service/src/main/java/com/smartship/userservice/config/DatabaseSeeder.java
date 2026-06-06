package com.smartship.userservice.config;

import com.smartship.userservice.entity.TierConfig;
import com.smartship.userservice.repository.TierConfigRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class DatabaseSeeder {

    @Bean
    public CommandLineRunner seedTierData(TierConfigRepository repository) {
        return args -> {
            // 🎯 ĐÃ THÊM LỆNH IF: Chỉ reset nếu DB đang trống hoặc đang dùng hệ thống 4 Rank cũ
            if (repository.count() < 5) {

                // Xóa sạch hệ thống cũ
                repository.deleteAll();

                // Khởi tạo hệ thống 5 mốc thăng hạng
                TierConfig tier1 = new TierConfig();
                tier1.setTierName("BRONZE");
                tier1.setMinPoints(0);

                TierConfig tier2 = new TierConfig();
                tier2.setTierName("SILVER");
                tier2.setMinPoints(2500);

                TierConfig tier3 = new TierConfig();
                tier3.setTierName("GOLD");
                tier3.setMinPoints(5000);

                TierConfig tier4 = new TierConfig();
                tier4.setTierName("PLATINUM");
                tier4.setMinPoints(10000);

                TierConfig tier5 = new TierConfig();
                tier5.setTierName("DIAMOND");
                tier5.setMinPoints(20000);

                // Tự động lưu 5 mốc này xuống DB
                repository.saveAll(List.of(tier1, tier2, tier3, tier4, tier5));
                System.out.println("✅ Tự động khởi tạo hệ thống 5 mốc Tier thành công!");
            } else {
                System.out.println("✅ Hệ thống Tier đã có dữ liệu, bỏ qua bước khởi tạo!");
            }
        };
    }
}