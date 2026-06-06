package vn.edu.shipmentservice.dto;


import lombok.Builder;
import lombok.Data;
import vn.edu.shipmentservice.entity.ShipmentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ShipmentResponseDTO {
    private Long id;
    private Long senderId;
    private String senderName;
    private String driverName;
    private Long driverId;
    private String pickupAddress;
    private Double pickupLongitude;
    private Double pickupLatitude;
    private String deliveryAddress;
    private Double deliveryLongitude;
    private Double deliveryLatitude;
    private String packageDescription;
    private BigDecimal packageValue;
    private BigDecimal shippingCost;
    private ShipmentStatus status;
    private LocalDateTime createdAt;
    private List<String> imageUrls;
    private Integer rating;
    private String vehicleType;
}
