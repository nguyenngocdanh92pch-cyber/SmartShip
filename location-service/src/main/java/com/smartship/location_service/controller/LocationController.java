package com.smartship.location_service.controller;

import com.smartship.location_service.dto.LocationUpdateRequest;
import com.smartship.location_service.service.LocationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/location")
@RequiredArgsConstructor
public class LocationController {

    private final LocationService locationService;

    @PostMapping("/update")
    public ResponseEntity<String> updateLocation(@RequestBody LocationUpdateRequest request) {
        locationService.processLocationUpdate(request);
        return ResponseEntity.ok("Cập nhật vị trí thành công!");
    }
}