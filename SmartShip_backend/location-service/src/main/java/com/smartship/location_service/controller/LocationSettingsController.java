package com.smartship.location_service.controller;

import com.smartship.location_service.service.LocationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class LocationSettingsController {

    private final LocationService locationService;

    @GetMapping("/geofence-check")
    public ResponseEntity<BigDecimal> checkGeofence(@RequestParam double lng, @RequestParam double lat) {
        // Gọi hàm từ LocationService (Nhớ đảm bảo bồ đã copy hàm checkGeofenceSurcharge vào LocationService như tui chỉ ở tin nhắn trước nha)
        BigDecimal surcharge = locationService.checkGeofenceSurcharge(lng, lat);
        return ResponseEntity.ok(surcharge);
    }
}