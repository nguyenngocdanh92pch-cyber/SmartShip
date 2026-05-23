package vn.edu.routingservice.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import vn.edu.routingservice.service.RoutingService;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RoutingServiceImpl implements RoutingService {

    private final RestTemplate restTemplate;

    // Lấy token tự động từ file application.yml
    @Value("${mapbox.access-token}")
    private String mapboxAccessToken;

    // Các Endpoint của Mapbox
    private static final String MAPBOX_DIRECTIONS_URL = "https://api.mapbox.com/directions/v5/mapbox/driving";
    private static final String MAPBOX_OPTIMIZATION_URL = "https://api.mapbox.com/optimized-trips/v1/mapbox/driving";

    @Override
    public RouteEstimate calculateDistanceAndCost(double originLng, double originLat, double destLng, double destLat) {
        try {
            // Mapbox bắt buộc dùng dấu "." cho thập phân và ";" để ngăn cách tọa độ
            String coordinates = String.format(java.util.Locale.US, "%f,%f;%f,%f", originLng, originLat, destLng, destLat);
            String urlString = MAPBOX_DIRECTIONS_URL + "/" + coordinates + "?overview=false&access_token=" + mapboxAccessToken;

            URI uri = URI.create(urlString);

            JsonNode response = restTemplate.getForObject(uri, JsonNode.class);

            if (response != null && "Ok".equals(response.get("code").asText())) {
                JsonNode route = response.get("routes").get(0);
                double distanceMeters = route.get("distance").asDouble();
                double distanceKm = distanceMeters / 1000.0;
                double durationSeconds = route.get("duration").asDouble();

                BigDecimal cost = calculateShippingFee(distanceKm);

                return new RouteEstimate(
                        String.format("%.1f km", distanceKm),
                        String.format("%.0f phút", durationSeconds / 60),
                        cost
                );
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi Mapbox Directions API: " + e.getMessage());
        }

        return new RouteEstimate("0 km", "0 phút", BigDecimal.ZERO);
    }

    @Override
    public DirectionsRoute optimizeDriverRoute(String coordinates) { // 🌟 Sửa tham số
        if (coordinates == null || coordinates.isEmpty() || !coordinates.contains(";")) {
            return new DirectionsRoute("Không có đơn hàng hoặc thiếu tọa độ", "[]");
        }

        try {
            // Không cần vòng lặp for StringBuilder nữa, nối thẳng vào URL
            String urlString = MAPBOX_OPTIMIZATION_URL + "/" + coordinates
                    + "?roundtrip=true&source=first&destination=any&access_token=" + mapboxAccessToken;

            URI uri = URI.create(urlString);
            JsonNode response = restTemplate.getForObject(uri, JsonNode.class);

            if (response != null && response.has("code") && "Ok".equals(response.get("code").asText())) {
                return new DirectionsRoute("Lộ trình tối ưu", response.get("waypoints").toString());
            } else {
                String mapboxError = response != null ? response.toString() : "Không có phản hồi từ Mapbox";
                System.err.println("⚠️ LỖI MAPBOX: " + mapboxError);
                return new DirectionsRoute("Mapbox Error: " + mapboxError, "[]");
            }

        } catch (Exception e) {
            System.err.println("Lỗi khi gọi Mapbox Optimization API: " + e.getMessage());
            return new DirectionsRoute("Lỗi kết nối", "[]");
        }
    }

    private BigDecimal calculateShippingFee(double distanceKm) {
        BigDecimal basePrice = new BigDecimal("15000"); // 15k mở cửa
        if (distanceKm <= 2.0) {
            return basePrice;
        }

        BigDecimal extraDistance = BigDecimal.valueOf(distanceKm - 2.0);
        BigDecimal pricePerKm = new BigDecimal("5000"); // 5k mỗi km tiếp theo

        return basePrice.add(extraDistance.multiply(pricePerKm)).setScale(0, RoundingMode.HALF_UP);
    }
}