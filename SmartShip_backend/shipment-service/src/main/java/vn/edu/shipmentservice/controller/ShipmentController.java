package vn.edu.shipmentservice.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
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

    // ==============================================================
    // 1. API DÀNH CHO NGƯỜI GỬI (SENDER)
    // ==============================================================

    /**
     * Tạo đơn hàng (Hỗ trợ đầy đủ Hình ảnh và Voucher nâng cao)
     */
    @PostMapping(value = "/", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ShipmentResponseDTO> createShipment(
            @RequestHeader("X-User-Id") Long senderId,
            @ModelAttribute ShipmentRequestDTO requestDTO,
            @RequestParam(value = "images", required = false) List<MultipartFile> imageFiles,
            @RequestParam(value = "voucherCode", required = false) String voucherCode) {

        // Giữ logic nâng cao truyền đủ 4 tham số khớp với Interface mới của bồ
        ShipmentResponseDTO response = shipmentService.createShipment(senderId, requestDTO, imageFiles, voucherCode);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Lấy lịch sử bằng Header
     */
    @GetMapping("/history")
    public ResponseEntity<List<ShipmentResponseDTO>> getSenderHistory(
            @RequestHeader("X-User-Id") Long senderId) {
        List<ShipmentResponseDTO> history = shipmentService.getHistoryBySender(senderId);
        return ResponseEntity.ok(history);
    }

    /**
     * Lấy toàn bộ danh sách lịch sử đơn hàng của người gửi (Fix data cho Flutter)
     */
    @GetMapping("/sender/{senderId}")
    public ResponseEntity<?> getShipmentsBySender(@PathVariable Long senderId) {
        List<ShipmentResponseDTO> shipments = shipmentService.getHistoryBySender(senderId);
        return ResponseEntity.ok(shipments);
    }

    /**
     * Lấy duy nhất 1 đơn hàng mới nhất đang hoạt động của người gửi
     */
    @GetMapping("/sender/{senderId}/latest")
    public ResponseEntity<?> getLatestShipmentBySender(@PathVariable Long senderId) {
        List<ShipmentResponseDTO> history = shipmentService.getHistoryBySender(senderId);
        if (history != null && !history.isEmpty()) {
            return ResponseEntity.ok(history.get(0));
        }
        return ResponseEntity.noContent().build();
    }

    /**
     * Xem chi tiết một đơn hàng bất kỳ
     */
    @GetMapping("/{id}")
    public ResponseEntity<ShipmentResponseDTO> getShipmentDetail(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long currentUserId) {
        ShipmentResponseDTO detail = shipmentService.getShipmentDetail(id, currentUserId);
        return ResponseEntity.ok(detail);
    }

    /**
     * Tích điểm và đánh giá tài xế
     */
    @PostMapping("/{id}/rate")
    public ResponseEntity<String> rateShipment(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long senderId,
            @RequestParam int rating) {
        shipmentService.rateShipment(id, senderId, rating);
        return ResponseEntity.ok("Đã đánh giá thành công!");
    }


    // ==============================================================
    // 2. API DÀNH CHO TÀI XẾ (DRIVER)
    // ==============================================================

    /**
     * Cập nhật trạng thái bằng Enum
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<ShipmentResponseDTO> updateStatus(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long driverId,
            @RequestParam ShipmentStatus status) {
        ShipmentResponseDTO response = shipmentService.updateShipmentStatus(id, driverId, status);
        return ResponseEntity.ok(response);
    }

    /**
     * API Cập nhật trạng thái dùng String (Hỗ trợ tương thích ngược cho code cũ của bạn bồ)
     */
    @PutMapping("/v2/{id}/status")
    public ResponseEntity<Shipment> updateShipmentStatusString(
            @PathVariable Long id,
            @RequestParam String status) {
        return ResponseEntity.ok(shipmentService.updateShipmentStatus(id, status));
    }

    /**
     * Lấy đơn xung quanh dựa vào tọa độ vị trí
     */
    @GetMapping("/available")
    public ResponseEntity<List<ShipmentResponseDTO>> getAvailableShipments(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng) {
        return ResponseEntity.ok(shipmentService.getAvailableShipments(lat, lng));
    }

    /**
     * Chấp nhận đơn hàng cơ bản
     */
    @PostMapping("/{id}/accept")
    public ResponseEntity<ShipmentResponseDTO> acceptShipment(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") Long driverId) {
        return ResponseEntity.ok(shipmentService.acceptShipment(id, driverId));
    }

    /**
     * Danh sách đơn đã nhận hiển thị lên Lộ Trình (Có kèm bảo mật phân quyền xem)
     */
    @GetMapping("/driver/{driverId}/accepted")
    public ResponseEntity<List<ShipmentResponseDTO>> getAcceptedShipments(
            @PathVariable Long driverId,
            @RequestHeader("X-User-Id") Long currentUserId) {
        if (!driverId.equals(currentUserId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(shipmentService.getAcceptedShipmentsByDriver(driverId));
    }

    /**
     * Tính toán thu nhập Dashboard tài xế theo chu kỳ (ngày/tuần/tháng)
     */
    @GetMapping("/earnings/driver/{driverId}")
    public ResponseEntity<EarningDashboardResponse> getDriverEarnings(
            @PathVariable Long driverId,
            @RequestParam(defaultValue = "daily") String period) {
        EarningDashboardResponse response = earningService.calculateEarnings(driverId, period);
        return ResponseEntity.ok(response);
    }

    // Thêm API này vào ShipmentController.java
    @PostMapping("/{id}/arrived-pickup")
    public ResponseEntity<String> notifyArrivedPickup(
            @PathVariable("id") Long shipmentId,
            @RequestHeader("X-User-Id") Long driverId) {

        shipmentService.notifyDriverArrivedAtPickup(shipmentId, driverId);
        return ResponseEntity.ok("Đã thông báo cho người gửi là tài xế đã đến lấy hàng.");
    }

    // ==============================================================
    // 3. CÁC API HỖ TRỢ ADMIN & QUẢN LÝ Hệ THỐNG
    // ==============================================================

    /**
     * LẤY DANH SÁCH TOÀN BỘ ĐƠN HÀNG HỆ THỐNG (DTO)
     */
    @GetMapping("/list")
    public ResponseEntity<List<ShipmentResponseDTO>> getAllShipments() {
        List<ShipmentResponseDTO> shipments = shipmentService.getAllShipments();
        return ResponseEntity.ok(shipments);
    }

    /**
     * API Lấy danh sách gốc (Hỗ trợ tương thích ngược trả về Entity cho code của bạn bồ)
     */
    @GetMapping("/v2/list")
    public ResponseEntity<List<Shipment>> getAllShipmentsRaw() {
        return ResponseEntity.ok(shipmentRepository.findAll());
    }

    /**
     * THỐNG KÊ DASHBOARD TỔNG QUAN NÂNG CAO (Doanh thu, biểu đồ giờ, logs hoạt động)
     */
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

    /**
     * API Thống kê Dashboard giản lược (Hỗ trợ giữ logic cũ của bạn bồ)
     */
    @GetMapping("/dashboard-stats")
    public ResponseEntity<Map<String, Object>> getSimpleDashboardStats() {
        return ResponseEntity.ok(shipmentService.getDashboardStats());
    }

    /**
     * ADMIN PHÁT LẠI 1 ĐƠN HÀNG THỦ CÔNG
     */
    @PutMapping("/republish/{id}")
    public ResponseEntity<String> republishSingleOrder(@PathVariable Long id) {
        Shipment s = shipmentRepository.findById(id).orElse(null);
        if (s != null && s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING) {
            s.setCreatedAt(LocalDateTime.now());
            shipmentRepository.save(s);
        }
        return ResponseEntity.ok("Đã phát lại đơn " + id);
    }

    /**
     * ADMIN PHÁT LẠI TOÀN BỘ ĐƠN KẸT QUÁ 10 PHÚT
     */
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

    /**
     * ADMIN HỦY ÉP BUỘC ĐƠN HÀNG
     */
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

    /**
     * TÀI XẾ BẤM NHẬN ĐƠN (CẬP NHẬT FULL THÔNG TIN XE)
     */
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

    /**
     * DÀNH CHO TRANG BÁO CÁO DOANH THU (ANALYTICS)
     */
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

    /**
     * DÀNH CHO TRANG GIÁM SÁT VẬN HÀNH (LIVE MAP - Đã fix lỗi ép kiểu triệt để)
     */
    @GetMapping("/live")
    public ResponseEntity<Map<String, Object>> getLiveOperations() {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Shipment> activeShipments = shipmentRepository.findAll().stream()
                    .filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.ACCEPTED ||
                            s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP)
                    .collect(Collectors.toList());

            long onlineDrivers = activeShipments.stream().map(Shipment::getDriverId).filter(Objects::nonNull).distinct().count();
            long movingOrders = activeShipments.stream().filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP).count();

            LocalDateTime tenMinsAgo = LocalDateTime.now().minusMinutes(10);
            List<Map<String, Object>> alerts = shipmentRepository.findAll().stream()
                    .filter(s -> s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PENDING &&
                            s.getCreatedAt() != null && s.getCreatedAt().isBefore(tenMinsAgo))
                    .map(s -> Map.<String, Object>of(
                            "id", "SH-" + s.getId(),
                            "driver", "Chưa có tài xế",
                            "issue", "Khẩn cấp: Đơn hàng kẹt quá lâu chưa ai nhận!",
                            "time", "Kẹt lúc " + String.format("%02d:%02d", s.getCreatedAt().getHour(), s.getCreatedAt().getMinute())
                    )).collect(Collectors.toList());

            List<Map<String, Object>> mapData = new ArrayList<>();
            for (Shipment s : activeShipments) {
                double lat, lng;
                if (s.getPickupLocation() != null) {
                    lat = s.getPickupLocation().getY();
                    lng = s.getPickupLocation().getX();
                } else {
                    lat = 10.7769 + (Math.random() - 0.5) * 0.03;
                    lng = 106.7009 + (Math.random() - 0.5) * 0.03;
                }

                mapData.add(Map.<String, Object>of(
                        "id", s.getId(),
                        "pos", new double[]{lat, lng},
                        "type", s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP ? "green" : "blue",
                        "desc", "Tài xế TX#" + s.getDriverId() + " - " + s.getVehicleType() + " (" +
                                (s.getStatus() == vn.edu.shipmentservice.entity.ShipmentStatus.PICKED_UP ? "Đang giao" : "Đang lấy hàng") + ")"
                ));
            }

            List<Map<String, Object>> logs = shipmentRepository.findTop5ByOrderByCreatedAtDesc().stream()
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

    /**
     * API Đồng bộ bản đồ Live Monitoring giản lược (Giữ tương thích cho bạn bồ)
     */
    @GetMapping("/live-monitoring")
    public ResponseEntity<Map<String, Object>> getLiveMonitoringData() {
        return ResponseEntity.ok(shipmentService.getLiveMonitoringData());
    }

    // ==============================================================
    // 4. CÁC API DÀNH CHO VÍ TÀI XẾ (RÚT TIỀN / LỊCH SỬ)
    // ==============================================================

    /**
     * Xem thông tin ví và lịch sử giao dịch tài xế
     */
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

    /**
     * Tài xế rút tiền về ngân hàng
     */
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