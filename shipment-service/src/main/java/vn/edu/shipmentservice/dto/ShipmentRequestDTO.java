package vn.edu.shipmentservice.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class ShipmentRequestDTO {
    private String pickupAddress;
    private String deliveryAddress;
    // Tọa độ điểm lấy hàng
    private double pickupLongitude;
    private double pickupLatitude;

    // Tọa độ điểm giao hàng
    private double deliveryLongitude;
    private double deliveryLatitude;
    private String packageDescription;
    private BigDecimal packageValue;
    private List<String> imageUrls; // Danh sách URL ảnh [cite: 143]
}
