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
import java.time.LocalDateTime;
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
    public RouteEstimate calculateDistanceAndCost(double originLng, double originLat, double destLng, double destLat, String vehicleType) {
        try {
            String coordinates = String.format(java.util.Locale.US, "%f,%f;%f,%f", originLng, originLat, destLng, destLat);
            String urlString = MAPBOX_DIRECTIONS_URL + "/" + coordinates + "?overview=false&access_token=" + mapboxAccessToken;

            JsonNode response = restTemplate.getForObject(URI.create(urlString), JsonNode.class);

            if (response != null && "Ok".equals(response.get("code").asText())) {
                JsonNode route = response.get("routes").get(0);
                double distanceKm = route.get("distance").asDouble() / 1000.0;
                double durationSeconds = route.get("duration").asDouble();

                // Tiến hành tính toán chuỗi giá cước nâng cấp
                BigDecimal finalCost = calculateAdvancedShippingFee(distanceKm, vehicleType, originLng, originLat);

                return new RouteEstimate(
                        String.format("%.1f km", distanceKm),
                        String.format("%.0f phút", durationSeconds / 60),
                        finalCost
                );
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi Mapbox Directions API: " + e.getMessage());
        }
        return new RouteEstimate("0 km", "0 phút", BigDecimal.ZERO);
    }

    private BigDecimal calculateAdvancedShippingFee(double distanceKm, String vehicleType, double originLng, double originLat) {
        // 1. Lấy cấu hình cơ bản từ CSDL qua Shipment Service
        BigDecimal baseFare = fetchSetting("baseFare", new BigDecimal("18000"));
        BigDecimal minFare = fetchSetting("minFare", new BigDecimal("20000"));
        BigDecimal pricePerKm = fetchSetting("pricePerKm", new BigDecimal("12000"));

        // Tính giá theo khoảng cách cơ bản giống yêu cầu cũ
        BigDecimal cost = minFare;
        if (distanceKm <= 1.0) {
            cost = baseFare;
        } else if (distanceKm > 2.0) {
            BigDecimal extraDistance = BigDecimal.valueOf(distanceKm - 1.0);
            cost = baseFare.add(extraDistance.multiply(pricePerKm));
            if (cost.compareTo(minFare) < 0) cost = minFare;
        }

        // 2. Áp dụng Hệ số phương tiện (Vehicle Coefficient)
        BigDecimal vehicleCoefficient = fetchSetting("vehicle_" + vehicleType, BigDecimal.ONE);
        cost = cost.multiply(vehicleCoefficient);

        // 3. Áp dụng Phụ phí thời gian (Giờ cao điểm & Ngày lễ)
        LocalDateTime now = LocalDateTime.now();
        BigDecimal timeMultiplier = BigDecimal.ONE;

        // Kiểm tra ngày lễ Việt Nam (Dương lịch cố định)
        if (isVietnameseHoliday(now)) {
            BigDecimal holidaySurchargePercent = fetchSetting("surcharge_holiday", new BigDecimal("20")); // Ví dụ: 20%
            timeMultiplier = timeMultiplier.add(holidaySurchargePercent.divide(new BigDecimal("100")));
        }
        // Nếu không phải ngày lễ, kiểm tra tiếp giờ cao điểm (7g-9g sáng và 5g-7g tối)
        else if (isPeakHour(now)) {
            BigDecimal peakSurchargePercent = fetchSetting("surcharge_peakHour", new BigDecimal("15")); // Ví dụ: 15%
            timeMultiplier = timeMultiplier.add(peakSurchargePercent.divide(new BigDecimal("100")));
        }
        cost = cost.multiply(timeMultiplier);

        // 4. Áp dụng Phụ phí vùng địa lý Geofencing (Cộng thêm tiền cố định)
        BigDecimal geofenceSurcharge = fetchGeofenceSurcharge(originLng, originLat);
        cost = cost.add(geofenceSurcharge);

        return cost.setScale(0, RoundingMode.HALF_UP);
    }

    private boolean isPeakHour(LocalDateTime now) {
        int hour = now.getHour();
        // Giờ cao điểm: 7:00 - 8:59 và 17:00 - 18:59
        return (hour >= 7 && hour < 9) || (hour >= 17 && hour < 19);
    }

    private boolean isVietnameseHoliday(LocalDateTime now) {
        int month = now.getMonthValue();
        int day = now.getDayOfMonth();
        // Kiểm tra các ngày lễ chính ở VN: 1/1, 30/4, 1/5, 2/9
        return (month == 1 && day == 1) || (month == 4 && day == 30) || (month == 5 && day == 1) || (month == 9 && day == 2);
    }

    private BigDecimal fetchSetting(String key, BigDecimal defaultValue) {
        try {
            // ĐỔI URL: Gọi qua API Gateway (Cổng 8080) và đúng đường dẫn của Shipment Service
            String url = "http://localhost:8080/shipments/settings/" + key;

            String value = restTemplate.getForObject(url, String.class);
            if (value != null && !value.isEmpty()) return new BigDecimal(value);
        } catch (Exception e) {
            System.err.println("Lỗi lấy cấu hình " + key + ": " + e.getMessage());
        }
        return defaultValue;
    }

    private BigDecimal fetchGeofenceSurcharge(double lng, double lat) {
        try {
            // Gọi sang Shipment Service để tận dụng hàm kiểm tra không gian địa lý PostGIS
            String url = String.format("http://localhost:8083/api/settings/geofence-check?lng=%f&lat=%f", lng, lat);
            String value = restTemplate.getForObject(url, String.class);
            if (value != null && !value.isEmpty()) return new BigDecimal(value);
        } catch (Exception e) {
            System.err.println("Lỗi kiểm tra vùng Geofencing: " + e.getMessage());
        }
        return BigDecimal.ZERO;
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

    @Override
    public RouteEstimate calculateDistanceForDriver(double originLng, double originLat, double destLng, double destLat) {
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


                return new RouteEstimate(
                        String.format("%.1f km", distanceKm),
                        String.format("%.0f phút", durationSeconds / 60),
                        null // 👉 Truyền null (hoặc BigDecimal.ZERO) cho giá trị cost
                );
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi Mapbox Directions API: " + e.getMessage());
        }

        return new RouteEstimate("0 km", "0 phút", null); // 👉 Tương tự, truyền null ở đây
    }
}