package vn.edu.routingservice.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.routingservice.service.RoutingService;

import java.util.List;

@RestController
@RequestMapping("/routing")
@RequiredArgsConstructor
public class RoutingController {

    private final RoutingService routingService;

    // 1. API dành cho khách hàng (Sender)
    @GetMapping("/estimate")
    public ResponseEntity<RoutingService.RouteEstimate> estimateRoute(
            @RequestParam double originLng,
            @RequestParam double originLat,
            @RequestParam double destLng,
            @RequestParam double destLat,
            @RequestParam String vehicleType) {

        RoutingService.RouteEstimate estimate = routingService.calculateDistanceAndCost(
                originLng, originLat, destLng, destLat, vehicleType);
        return ResponseEntity.ok(estimate);
    }

    // 2. API dành cho Tài xế (Driver) - Đã thêm vehicleType
    @GetMapping("/driver/estimate")
    public ResponseEntity<RoutingService.RouteEstimate> estimateRouteForDriver(
            @RequestParam double originLng,
            @RequestParam double originLat,
            @RequestParam double destLng,
            @RequestParam double destLat,
            @RequestParam String vehicleType) { // 🌟 Đã khai báo nhận biến vehicleType

        RoutingService.RouteEstimate estimate = routingService.calculateDistanceAndCost(
                originLng, originLat, destLng, destLat, vehicleType); // 🌟 Đã truyền đủ 5 tham số
        return ResponseEntity.ok(estimate);
    }

    // 3. API dành cho tài xế: Tối ưu hóa thứ tự các điểm lấy/giao hàng
    @GetMapping("/optimize")
    public ResponseEntity<RoutingService.DirectionsRoute> optimizeRoute(
            @RequestParam String coordinates) {

        RoutingService.DirectionsRoute optimizedRoute =
                routingService.optimizeDriverRoute(coordinates);

        return ResponseEntity.ok(optimizedRoute);
    }
}