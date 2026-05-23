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

    @GetMapping("/estimate")
    public ResponseEntity<RoutingService.RouteEstimate> estimateRoute(
            @RequestParam double originLng,
            @RequestParam double originLat,
            @RequestParam double destLng,
            @RequestParam double destLat) {

        // Truyền 4 tọa độ xuống cho Service tính toán
        RoutingService.RouteEstimate estimate = routingService.calculateDistanceAndCost(originLng, originLat, destLng, destLat);
        return ResponseEntity.ok(estimate);
    }

    // API dành cho tài xế: Tối ưu hóa thứ tự các điểm lấy/giao hàng
    @GetMapping("/optimize")
    public ResponseEntity<RoutingService.DirectionsRoute> optimizeRoute(
            @RequestParam String coordinates) { // 🌟 Chỉ nhận 1 chuỗi đã nối sẵn từ Flutter

        RoutingService.DirectionsRoute optimizedRoute =
                routingService.optimizeDriverRoute(coordinates);

        return ResponseEntity.ok(optimizedRoute);
    }
}
