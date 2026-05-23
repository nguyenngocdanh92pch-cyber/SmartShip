package com.smartship.location_service.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "driver_locations")
public class LocationRecord {
    @Id
    private String id;
    private String driverId;
    private double latitude;
    private double longitude;
    private Instant timestamp;
}