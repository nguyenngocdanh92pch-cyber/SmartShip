package vn.edu.shipmentservice.controller;


import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.edu.shipmentservice.dto.EarningDashboardResponse;
import vn.edu.shipmentservice.dto.ShipmentRequestDTO;
import vn.edu.shipmentservice.dto.ShipmentResponseDTO;
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;
import vn.edu.shipmentservice.repository.DriverWalletRepository;
import vn.edu.shipmentservice.repository.ShipmentRepository;
import vn.edu.shipmentservice.repository.WalletTransactionRepository;
import vn.edu.shipmentservice.service.EarningService;
import vn.edu.shipmentservice.service.ShipmentService;
import vn.edu.shipmentservice.service.WalletService;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/shipments")
@RequiredArgsConstructor
public class ShipmentController {

    private final ShipmentService shipmentService;
    private final EarningService earningService;
    private final ShipmentRepository shipmentRepository;
    private final DriverWalletRepository driverWalletRepository;
    private final WalletTransactionRepository walletTransactionRepository;
    private final WalletService walletService;

    // --- API DÀNH CHO NGƯỜI GỬI (SENDER) ---

    // Tạo đơn hàng [cite: 129]
    @PostMapping(value = "/", consumes = "multipart/form-data")
    public ResponseEntity<ShipmentResponseDTO> createShipment(
            @RequestHeader("X-User-Id") Long senderId,
            @ModelAttribute ShipmentRequestDTO requestDTO,
            @RequestParam(value = "images", required = false) List<MultipartFile> imageFiles) {

        // Truyền đủ 3 tham số xuống cho Service
        ShipmentResponseDTO response = shipmentService.createShipment(senderId, requestDTO, imageFiles);
        return ResponseEntity.ok(response);
    }

    // Lấy lịch sử [cite: 130]
    @GetMapping("/history")
    public ResponseEntity<List<ShipmentResponseDTO>> getSenderHistory(
            @RequestHeader("X-User-Id") Long senderId) {
        List<ShipmentResponseDTO> history = shipmentService.getHistoryBySender(senderId);
        return ResponseEntity.ok(history);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ShipmentResponseDTO> getShipmentDetail(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long currentUserId) {


        ShipmentResponseDTO detail = shipmentService.getShipmentDetail(id, currentUserId);


        return ResponseEntity.ok(detail);
    }

    // Tích điểm và đánh giá tài xế (POST /{id}/rate)
    @PostMapping("/{id}/rate")
    public ResponseEntity<String> rateShipment(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long senderId,
            @RequestParam int rating) {
        shipmentService.rateShipment(id, senderId, rating);
        return ResponseEntity.ok("Đã đánh giá thành công!");
    }

    // --- API DÀNH CHO TÀI XẾ (DRIVER) ---

    // Cập nhật trạng thái (PENDING -> ACCEPTED -> PICKED_UP -> AT_WAREHOUSE) [cite: 136]
    @PutMapping("/{id}/status")
    public ResponseEntity<ShipmentResponseDTO> updateStatus(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long driverId,
            @RequestParam ShipmentStatus status) {
        ShipmentResponseDTO response = shipmentService.updateShipmentStatus(id, driverId, status);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/available")
    public ResponseEntity<List<ShipmentResponseDTO>> getAvailableShipments(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng) {
        // Truyền tọa độ xuống tầng Service
        return ResponseEntity.ok(shipmentService.getAvailableShipments(lat, lng));
    }

    // Chấp nhận đơn hàng (POST /{id}/accept)
    @PostMapping("/{id}/accept")
    public ResponseEntity<ShipmentResponseDTO> acceptShipment(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long driverId) {
        return ResponseEntity.ok(shipmentService.acceptShipment(id, driverId));
    }

    // Lấy danh sách đơn hàng ĐÃ NHẬN (ACCEPTED) của tài xế để hiển thị lên màn hình Lộ trình
    @GetMapping("/driver/{driverId}/accepted")
    public ResponseEntity<List<ShipmentResponseDTO>> getAcceptedShipments(
            @PathVariable Long driverId,
            @RequestHeader("X-User-Id") Long currentUserId) {

        // Xác thực bảo mật: Tài xế nào chỉ được xem đơn của tài xế đó
        if (!driverId.equals(currentUserId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        List<ShipmentResponseDTO> acceptedShipments = shipmentService.getAcceptedShipmentsByDriver(driverId);
        return ResponseEntity.ok(acceptedShipments);
    }

    @GetMapping("/earnings/driver/{driverId}")
    public ResponseEntity<EarningDashboardResponse> getDriverEarnings(
            @PathVariable Long driverId,
            @RequestParam(defaultValue = "daily") String period) {

        EarningDashboardResponse response = earningService.calculateEarnings(driverId, period);
        return ResponseEntity.ok(response);
    }

    // 1. LẤY DANH SÁCH ĐƠN HÀNG
    // ==============================================================
    @GetMapping("/list")
    public ResponseEntity<List<ShipmentResponseDTO>> getAllShipments() {
        List<ShipmentResponseDTO> shipments = shipmentService.getAllShipments();
        return ResponseEntity.ok(shipments);
    }
    // ==============================================================
    // 2. THỐNG KÊ DASHBOARD TỔNG QUAN
    // ==============================================================
    @GetMapping("/admin/dashboard-stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        Map<String, Object> response = new HashMap<>();
        try {
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime startOfToday = now.toLocalDate().atStartOfDay();
            LocalDateTime startOfYesterday = startOfToday.minusDays(1);

            Map<String, Object> today = shipmentRepository.getStatsBetween(startOfToday, now);
            Map<String, Object> yesterday = shipmentRepository.getStatsBetween(startOfYesterday, startOfToday);

            double revToday = today.get("revenue") != null ? ((Number) today.get("revenue")).doubleValue() : 0.0;
            double revYesterday = yesterday.get("revenue") != null ? ((Number) yesterday.get("revenue")).doubleValue() : 0.0;
            long ordersToday = today.get("count") != null ? ((Number) today.get("count")).longValue() : 0L;
            long ordersYesterday = yesterday.get("count") != null ? ((Number) yesterday.get("count")).longValue() : 0L;

            long revTrend = revYesterday == 0 ? (revToday > 0 ? 100 : 0) : Math.round(((revToday - revYesterday) / revYesterday) * 100);
            long orderTrend = ordersYesterday == 0 ? (ordersToday > 0 ? 100 : 0) : Math.round(((double)(ordersToday - ordersYesterday) / ordersYesterday) * 100);

            List<Map<String, Object>> rawChartData = shipmentRepository.getHourlyStatsToday();
            List<Map<String, Object>> formattedChart = rawChartData.stream().map(item -> {
                Map<String, Object> m = new HashMap<>();
                m.put("time", String.format("%02d:00", ((Number) item.get("hour")).intValue()));
                m.put("orders", item.get("count"));
                return m;
            }).collect(Collectors.toList());

            List<Map<String, Object>> activities = shipmentRepository.findTop5ByOrderByCreatedAtDesc().stream().map(s -> {
                Map<String, Object> act = new HashMap<>();
                act.put("id", s.getId());
                act.put("type", "success");
                act.put("text", "Đơn hàng #" + s.getId() + " vừa được giao thành công.");
                act.put("time", "Vừa xong");
                return act;
            }).collect(Collectors.toList());

            response.put("revenue", revToday);
            response.put("revenueTrend", revTrend);
            response.put("totalOrders", ordersToday);
            response.put("orderTrend", orderTrend);
            response.put("chartData", formattedChart);
            response.put("activities", activities);

        } catch (Exception e) {
            response.put("error", e.getMessage());
        }
        return ResponseEntity.ok(response);
    }

    // ==============================================================
    // 3. API: ADMIN PHÁT LẠI 1 ĐƠN HÀNG THỦ CÔNG
    // ==============================================================
    @PutMapping("/republish/{id}")
    public ResponseEntity<String> republishSingleOrder(@PathVariable Long id) {
        Shipment s = shipmentRepository.findById(id).orElse(null);
        if (s != null && s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING) {
            s.setCreatedAt(LocalDateTime.now());
            shipmentRepository.save(s);
        }
        return ResponseEntity.ok("Đã phát lại đơn " + id);
    }

    // ==============================================================
    // 4. API: ADMIN PHÁT LẠI TOÀN BỘ ĐƠN KẸT
    // ==============================================================
    @PutMapping("/republish-all")
    public ResponseEntity<String> republishAllStuckOrders() {
        LocalDateTime tenMinsAgo = LocalDateTime.now().minusMinutes(10);
        List<Shipment> stuckOrders = shipmentRepository.findAll().stream()
                .filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING
                        && s.getCreatedAt() != null
                        && s.getCreatedAt().isBefore(tenMinsAgo))
                .collect(Collectors.toList());

        for (Shipment s : stuckOrders) {
            s.setCreatedAt(LocalDateTime.now());
            shipmentRepository.save(s);
        }
        return ResponseEntity.ok("Đã phát lại toàn bộ đơn kẹt");
    }

    // ==============================================================
    // 5. API: ADMIN HỦY ÉP BUỘC ĐƠN HÀNG
    // ==============================================================
    @PutMapping("/cancel/{id}")
    public ResponseEntity<String> forceCancelOrder(@PathVariable Long id) {
        Shipment s = shipmentRepository.findById(id).orElse(null);
        if (s != null) {
            s.setStatus(vn.edu.shipmentservice.entity.ShipmentStatus.CANCELLED);
            shipmentRepository.save(s);
            return ResponseEntity.ok("Đã hủy ép buộc đơn " + id);
        }
        return ResponseEntity.badRequest().body("Không tìm thấy đơn hàng");
    }

    // ==============================================================
    // 6. API: TÀI XẾ BẤM NHẬN ĐƠN (CẬP NHẬT FULL THÔNG TIN XE)
    // ==============================================================
    @PutMapping("/accept/{id}")
    public ResponseEntity<String> driverAcceptOrder(
            @PathVariable Long id,
            @RequestParam Long driverId,
            @RequestParam String vehicleType,
            @RequestParam String licensePlate,
            @RequestParam(required = false) String vehicleBrand,
            @RequestParam(required = false) String vehicleModel,
            @RequestParam(required = false) String vehicleColor) {

        Shipment s = shipmentRepository.findById(id).orElse(null);
        if (s != null && s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING) {
            s.setDriverId(driverId);
            s.setStatus(vn.edu.shipmentservice.entity.ShipmentStatus.ACCEPTED);

            // Cập nhật thông tin xe
            s.setVehicleType(vehicleType);
            s.setDriverLicensePlate(licensePlate);
            s.setDriverVehicleBrand(vehicleBrand);
            s.setDriverVehicleModel(vehicleModel);
            s.setDriverVehicleColor(vehicleColor);

            s.setAcceptedAt(LocalDateTime.now());
            shipmentRepository.save(s);
            return ResponseEntity.ok("Tài xế nhận đơn thành công!");
        }
        return ResponseEntity.badRequest().body("Lỗi nhận đơn! Đơn không tồn tại hoặc đã có người nhận.");
    }

    // ==============================================================
    // 7. API: DÀNH CHO TRANG BÁO CÁO DOANH THU (ANALYTICS)
    // ==============================================================
    @GetMapping("/analytics")
    public ResponseEntity<Map<String, Object>> getFullAnalytics() {
        Map<String, Object> res = new HashMap<>();
        try {
            Long totalOrders = shipmentRepository.count();
            Long completed = shipmentRepository.countCompletedOrders();
            Long cancelled = shipmentRepository.countCancelledOrders();

            double cancelRate = totalOrders == 0 ? 0 : Math.round(((double)cancelled / totalOrders) * 100 * 10.0) / 10.0;

            res.put("totalRevenue", shipmentRepository.getTotalRevenue());
            res.put("totalCompleted", completed);
            res.put("cancelRate", cancelRate);
            res.put("revenueChart", shipmentRepository.getRevenueChartData());
            res.put("peakHourChart", shipmentRepository.getPeakHourChartData());
            res.put("vehicleChart", shipmentRepository.getVehicleDistribution());

        } catch (Exception e) {
            res.put("error", e.getMessage());
        }
        return ResponseEntity.ok(res);
    }

    // ==============================================================
    // 8. API MỚI: DÀNH CHO TRANG GIÁM SÁT VẬN HÀNH (LIVE MAP)
    // ==============================================================
    @GetMapping("/live")
    public ResponseEntity<Map<String, Object>> getLiveOperations() {
        Map<String, Object> res = new HashMap<>();
        try {
            // 1. Kéo các đơn đang hoạt động (Đã nhận hoặc Đang giao)
            List<Shipment> activeShipments = shipmentRepository.findAll().stream()
                    .filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.ACCEPTED ||
                            s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP)
                    .collect(Collectors.toList());

            // Đếm số lượng tài xế online (Distinct ID) và đơn đang di chuyển
            long onlineDrivers = activeShipments.stream().map(Shipment::getDriverId).filter(Objects::nonNull).distinct().count();
            long movingOrders = activeShipments.stream().filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP).count();

            // 2. Kéo sự cố (Lấy các đơn PENDING bị kẹt hơn 10 phút làm cảnh báo)
            LocalDateTime tenMinsAgo = LocalDateTime.now().minusMinutes(10);
            List<Map<String, Object>> alerts = shipmentRepository.findAll().stream()
                    .filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING &&
                            s.getCreatedAt() != null && s.getCreatedAt().isBefore(tenMinsAgo))
                    // 🚀 FIX LỖI ÉP KIỂU TẠI ĐÂY: Dùng Map.<String, Object>of
                    .map(s -> Map.<String, Object>of(
                            "id", "SH-" + s.getId(),
                            "driver", "Chưa có tài xế",
                            "issue", "Khẩn cấp: Đơn hàng kẹt quá lâu chưa ai nhận!",
                            "time", "Kẹt lúc " + String.format("%02d:%02d", s.getCreatedAt().getHour(), s.getCreatedAt().getMinute())
                    )).collect(Collectors.toList());

            // 3. Tọa độ bản đồ (Map Data)
            List<Map<String, Object>> mapData = new ArrayList<>();
            for (Shipment s : activeShipments) {
                double lat, lng;
                // Nếu DB có lưu tọa độ thật (PostGIS Point) thì lấy, không thì giả lập quanh Q1
                if (s.getPickupLocation() != null) {
                    lat = s.getPickupLocation().getY();
                    lng = s.getPickupLocation().getX();
                } else {
                    lat = 10.7769 + (Math.random() - 0.5) * 0.03;
                    lng = 106.7009 + (Math.random() - 0.5) * 0.03;
                }

                // 🚀 FIX LỖI ÉP KIỂU TẠI ĐÂY
                mapData.add(Map.<String, Object>of(
                        "id", s.getId(),
                        "pos", new double[]{lat, lng},
                        "type", s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP ? "green" : "blue",
                        "desc", "Tài xế TX#" + s.getDriverId() + " - " + s.getVehicleType() + " (" +
                                (s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP ? "Đang giao" : "Đang lấy hàng") + ")"
                ));
            }

            // 4. Nhật ký Live (Lấy 5 đơn mới nhất)
            List<Map<String, Object>> logs = shipmentRepository.findTop5ByOrderByCreatedAtDesc().stream()
                    // 🚀 FIX LỖI ÉP KIỂU TẠI ĐÂY: Dùng Map.<String, Object>of
                    .map(s -> Map.<String, Object>of(
                            "id", "SH-" + s.getId(),
                            "text", "Đơn hàng vừa cập nhật trạng thái thành: " + s.getStatus().name()
                    )).collect(Collectors.toList());

            res.put("onlineDrivers", onlineDrivers);
            res.put("movingOrders", movingOrders);
            res.put("alerts", alerts);
            res.put("mapData", mapData);
            res.put("logs", logs);

        } catch (Exception e) {
            res.put("error", e.getMessage());
        }
        return ResponseEntity.ok(res);
    }

    // ==============================================================
    // CÁC API DÀNH CHO VÍ TÀI XẾ (RÚT TIỀN / LỊCH SỬ)
    // ==============================================================
    @GetMapping("/wallet/my-wallet")
    public ResponseEntity<Map<String, Object>> getMyWallet(@RequestHeader("X-User-Id") Long driverId) {
        Map<String, Object> response = new HashMap<>();

        vn.edu.shipmentservice.entity.DriverWallet wallet = driverWalletRepository.findById(driverId).orElse(null);
        BigDecimal currentBalance = (wallet != null && wallet.getBalance() != null)
                ? wallet.getBalance()
                : BigDecimal.ZERO;

        List<vn.edu.shipmentservice.entity.WalletTransaction> transactions =
                walletTransactionRepository.findByDriverIdOrderByCreatedAtDesc(driverId);

        response.put("balance", currentBalance);
        response.put("transactions", transactions);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/wallet/withdraw")
    public ResponseEntity<String> withdrawMoney(
            @RequestHeader("X-User-Id") Long driverId,
            @RequestParam BigDecimal amount,
            @RequestParam String bankInfo) {

        if (amount.compareTo(new BigDecimal("50000")) < 0) {
            return ResponseEntity.badRequest().body("Số tiền rút tối thiểu là 50,000đ");
        }

        boolean success = walletService.withdrawMoney(driverId, amount, bankInfo);

        if (success) {
            return ResponseEntity.ok("Yêu cầu rút tiền thành công!");
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Số dư không đủ.");
        }
    }


}
