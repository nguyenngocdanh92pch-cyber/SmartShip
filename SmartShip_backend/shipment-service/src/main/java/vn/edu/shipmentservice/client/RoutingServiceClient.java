package vn.edu.shipmentservice.client;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.math.BigDecimal;

@Component
@RequiredArgsConstructor
public class RoutingServiceClient {

    private final RestTemplate restTemplate;

    private final String API_GATEWAY_URL = "http://localhost:8080/routing";

    public RouteEstimateDTO getEstimate(double originLng, double originLat, double destLng, double destLat, String vehicleType) {

        String url = String.format("%s/estimate?originLng=%s&originLat=%s&destLng=%s&destLat=%s&vehicleType=%s",
                API_GATEWAY_URL, originLng, originLat, destLng, destLat, vehicleType);

        // Gọi API GET và tự động map kết quả JSON trả về vào object RouteEstimateDTO
        return restTemplate.getForObject(url, RouteEstimateDTO.class);
    }

    // DTO nội bộ hứng dữ liệu trả về từ Routing Service
    public record RouteEstimateDTO(String distance, String duration, BigDecimal cost) {}
}