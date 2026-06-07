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

    // ==============================================================
    // 1. HÀM TÍNH KHOẢNG CÁCH VÀ GIÁ TIỀN CHO KHÁCH HÀNG
    // ==============================================================
    @Override
    public RouteEstimate calculateDistanceAndCost(double originLng, double originLat, double destLng, double destLat, String vehicleType) {
        try {
            // Mapbox bắt buộc dùng dấu "." cho thập phân và ";" để ngăn cách tọa độ
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


    @Override
    public RouteEstimate calculateDistanceForDriver(double originLng, double originLat, double destLng, double destLat) {
        try {
            String coordinates = String.format(java.util.Locale.US, "%f,%f;%f,%f", originLng, originLat, destLng, destLat);
            String urlString = MAPBOX_DIRECTIONS_URL + "/" + coordinates + "?overview=false&access_token=" + mapboxAccessToken;

            URI uri = URI.create(urlString);
            JsonNode response = restTemplate.getForObject(uri, JsonNode.class);

            if (response != null && "Ok".equals(response.get("code").asText())) {
                JsonNode route = response.get("routes").get(0);
                double distanceKm = route.get("distance").asDouble() / 1000.0;
                double durationSeconds = route.get("duration").asDouble();

                return new RouteEstimate(
                        String.format("%.1f km", distanceKm),
                        String.format("%.0f phút", durationSeconds / 60),
                        null
                );
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi Mapbox Directions API cho Tài xế: " + e.getMessage());
        }

        return new RouteEstimate("0 km", "0 phút", null);
    }

    // ==============================================================
    // 3. HÀM TỐI ƯU HÓA LỘ TRÌNH (NHIỀU ĐIỂM DỪNG)
    // ==============================================================
    @Override
    public DirectionsRoute optimizeDriverRoute(String coordinates) {
        if (coordinates == null || coordinates.isEmpty() || !coordinates.contains(";")) {
            return new DirectionsRoute("Không có đơn hàng hoặc thiếu tọa độ", "[]");
        }

        try {
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



    private BigDecimal calculateAdvancedShippingFee(double distanceKm, String vehicleType, double originLng, double originLat) {
        // 1. Lấy cấu hình cơ bản từ CSDL
        BigDecimal baseFare = fetchSetting("baseFare", new BigDecimal("18000"));
        BigDecimal minFare = fetchSetting("minFare", new BigDecimal("20000"));
        BigDecimal pricePerKm = fetchSetting("pricePerKm", new BigDecimal("12000"));

        // Tính giá theo khoảng cách cơ bản
        BigDecimal cost = minFare;
        if (distanceKm <= 1.0) {
            cost = baseFare;
        } else if (distanceKm > 2.0) {
            BigDecimal extraDistance = BigDecimal.valueOf(distanceKm - 1.0);
            cost = baseFare.add(extraDistance.multiply(pricePerKm));
            if (cost.compareTo(minFare) < 0) cost = minFare;
        }

        // 2. Áp dụng Hệ số phương tiện (Vehicle Coefficient)
        // Nếu vehicleType bị null (ví dụ user quên chọn), mặc định hệ số là 1.0 (xe máy)
        if (vehicleType != null) {
            BigDecimal vehicleCoefficient = fetchSetting("vehicle_" + vehicleType, BigDecimal.ONE);
            cost = cost.multiply(vehicleCoefficient);
        }

        // 3. Áp dụng Phụ phí thời gian (Giờ cao điểm & Ngày lễ)
        LocalDateTime now = LocalDateTime.now();
        BigDecimal timeMultiplier = BigDecimal.ONE;

        if (isVietnameseHoliday(now)) {
            BigDecimal holidaySurchargePercent = fetchSetting("surcharge_holiday", new BigDecimal("20")); // 20%
            timeMultiplier = timeMultiplier.add(holidaySurchargePercent.divide(new BigDecimal("100")));
        } else if (isPeakHour(now)) {
            BigDecimal peakSurchargePercent = fetchSetting("surcharge_peakHour", new BigDecimal("15")); // 15%
            timeMultiplier = timeMultiplier.add(peakSurchargePercent.divide(new BigDecimal("100")));
        }
        cost = cost.multiply(timeMultiplier);

        // 4. Áp dụng Phụ phí vùng địa lý Geofencing
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
        // Ngày lễ: 1/1, 30/4, 1/5, 2/9
        return (month == 1 && day == 1) || (month == 4 && day == 30) || (month == 5 && day == 1) || (month == 9 && day == 2);
    }

    private BigDecimal fetchSetting(String key, BigDecimal defaultValue) {
        try {
            // Gọi qua API Gateway (Cổng 8080)
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
            // Gọi sang Shipment Service (PostGIS)
            String url = String.format("http://localhost:8083/api/settings/geofence-check?lng=%f&lat=%f", lng, lat);
            String value = restTemplate.getForObject(url, String.class);
            if (value != null && !value.isEmpty()) return new BigDecimal(value);
        } catch (Exception e) {
            System.err.println("Lỗi kiểm tra vùng Geofencing: " + e.getMessage());
        }
        return BigDecimal.ZERO;
    }
}