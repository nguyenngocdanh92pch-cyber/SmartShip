package com.smartship.location_service.dto;

import lombok.Data;

@Data
public class LocationUpdateRequest {
    private String driverId;
    private double latitude;
    private double longitude;
}