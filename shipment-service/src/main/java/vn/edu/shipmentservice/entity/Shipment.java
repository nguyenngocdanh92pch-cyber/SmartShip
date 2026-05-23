package vn.edu.shipmentservice.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.locationtech.jts.geom.Point;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "shipments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Shipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // [cite: 104]

    @Column(name = "sender_id", nullable = false)
    private Long senderId; // [cite: 105]

    @Column(name = "driver_id")
    private Long driverId; // [cite: 106]

    @Column(name = "pickup_address", nullable = false)
    private String pickupAddress; // [cite: 107]

    @Column(name = "pickup_location", columnDefinition = "geometry(Point,4326)")
    private Point pickupLocation; // [cite: 108]

    @Column(name = "delivery_address")
    private String deliveryAddress;

    @Column(name = "delivery_location", columnDefinition = "geometry(Point,4326)")
    private Point deliveryLocation;

    @Column(name = "package_description")
    private String packageDescription; // [cite: 109]

    @Column(name = "package_value")
    private BigDecimal packageValue; // [cite: 110]

    @Column(name = "shipping_cost")
    private BigDecimal shippingCost; // [cite: 111]

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ShipmentStatus status = ShipmentStatus.PENDING; // [cite: 112]

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt; // [cite: 113]

    // Cột lưu loại xe
    @Column(name = "vehicle_type")
    private String vehicleType;

    // Cột lưu biển số xe
    @Column(name = "driver_license_plate")
    private String driverLicensePlate;

    // 🚀 THÊM 3 DÒNG NÀY ĐỂ LƯU CHI TIẾT XE
    @Column(name = "driver_vehicle_brand")
    private String driverVehicleBrand;

    @Column(name = "driver_vehicle_model")
    private String driverVehicleModel;

    @Column(name = "driver_vehicle_color")
    private String driverVehicleColor;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt; // [cite: 114]

    @Column(name = "picked_up_at")
    private LocalDateTime pickedUpAt; // [cite: 115]

    @org.hibernate.annotations.UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Mapping 1-N với bảng package_images
    @OneToMany(mappedBy = "shipment", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PackageImage> packageImages = new ArrayList<>();

    @Column(name = "rating") private Integer rating;
}
