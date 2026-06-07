package com.smartship.location_service.service;

import com.smartship.location_service.dto.LocationUpdateRequest;
import com.smartship.location_service.entity.LocationRecord;
import com.smartship.location_service.repository.LocationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class LocationService {

    private final LocationRepository locationRepository;
    private final StringRedisTemplate redisTemplate;

    public void processLocationUpdate(LocationUpdateRequest request) {
        // Map DTO sang Entity
        LocationRecord entity = LocationRecord.builder()
                .driverId(request.getDriverId())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .timestamp(Instant.now())
                .build();

        // Lưu vào MongoDB
        locationRepository.save(entity);
        System.out.println("Đã lưu GPS cho tài xế: " + request.getDriverId());

        // Đẩy lên Redis
        String message = String.format("{\"driverId\":\"%s\", \"lat\":%f, \"lng\":%f}",
                request.getDriverId(), request.getLatitude(), request.getLongitude());
        redisTemplate.convertAndSend("driver-location-channel", message);
        System.out.println("Đã đẩy lên Redis!");
    }

    // ==============================================================
    // 🌟 THÊM HÀM NÀY ĐỂ FIX LỖI GEOFENCING BÊN ROUTING SERVICE GỌI SANG
    // ==============================================================
    public BigDecimal checkGeofenceSurcharge(double lng, double lat) {
        // Tạm thời trả về 0 (Không tính phụ phí vùng) để App không bị lỗi 404
        // Sau này có thuật toán kiểm tra vùng nội thành/ngoại thành thì code tiếp vào đây
        return BigDecimal.ZERO;
    }
}