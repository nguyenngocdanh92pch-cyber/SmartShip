package vn.edu.shipmentservice.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import vn.edu.shipmentservice.client.AuthServiceClient;
import vn.edu.shipmentservice.client.RoutingServiceClient;
import vn.edu.shipmentservice.client.UserServiceClient;
import vn.edu.shipmentservice.dto.ShipmentRequestDTO;
import vn.edu.shipmentservice.dto.ShipmentResponseDTO;
import vn.edu.shipmentservice.dto.UserAuthDTO;
import vn.edu.shipmentservice.entity.PackageImage;
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;
import vn.edu.shipmentservice.repository.ShipmentRepository;
import vn.edu.shipmentservice.repository.VoucherRepository;
import vn.edu.shipmentservice.service.GcsStorageService;
import vn.edu.shipmentservice.service.ShipmentService;
import vn.edu.shipmentservice.service.WalletService;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ShipmentServiceImpl implements ShipmentService {

    private final ShipmentRepository shipmentRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory();
    private final RoutingServiceClient routingServiceClient;
    private final GcsStorageService gcsStorageService;
    private final WalletService walletService;
    private final AuthServiceClient authServiceClient;

    @Autowired
    private VoucherRepository voucherRepository;

    @Autowired
    private UserServiceClient userServiceClient;

    @Override
    @Transactional
    public ShipmentResponseDTO createShipment(Long senderId, ShipmentRequestDTO request, List<MultipartFile> imageFiles, String voucherCode) {
        RoutingServiceClient.RouteEstimateDTO estimate = routingServiceClient.getEstimate(
                request.getPickupLongitude(),
                request.getPickupLatitude(),
                request.getDeliveryLongitude(),
                request.getDeliveryLatitude(),
                request.getVehicleType()
        );

        // =======================================================
        // 🚀 XỬ LÝ TRỪ TIỀN VOUCHER TỪ DATABASE THẬT
        // =======================================================
        BigDecimal finalCost = estimate.cost();

        if (voucherCode != null && !voucherCode.trim().isEmpty()) {
            try {
                // 1. Dùng Optional để hứng kết quả từ DB
                var voucherOpt = voucherRepository.findByCode(voucherCode);

                // 2. Kiểm tra xem trong hộp có Voucher không
                if (voucherOpt.isPresent()) {
                    var voucher = voucherOpt.get(); // Lấy đối tượng Voucher ra khỏi hộp

                    // 3. Lấy số tiền giảm giá từ Entity (Tên hàm đúng là getDiscountAmount)
                    BigDecimal discountAmount = voucher.getDiscountAmount();

                    finalCost = finalCost.subtract(discountAmount);

                    // 4. Bắt lỗi không cho phép âm tiền
                    if (finalCost.compareTo(BigDecimal.ZERO) < 0) {
                        finalCost = BigDecimal.ZERO;
                    }

                    log.info("✅ Áp dụng mã {}: Giá gốc {} - Giảm {} = Cần thu {}",
                            voucherCode, estimate.cost(), discountAmount, finalCost);
                } else {
                    log.warn("❌ Khách nhập mã {} nhưng không tìm thấy trong DB!", voucherCode);
                }
            } catch (Exception e) {
                log.error("Lỗi khi xử lý voucher {}: {}", voucherCode, e.getMessage());
            }
        }

        Point location = geometryFactory.createPoint(new Coordinate(request.getPickupLongitude(), request.getPickupLatitude()));
        location.setSRID(4326);

        Point deliveryLoc = geometryFactory.createPoint(new Coordinate(request.getDeliveryLongitude(), request.getDeliveryLatitude()));
        deliveryLoc.setSRID(4326);

        Shipment shipment = Shipment.builder()
                .senderId(senderId)
                .pickupAddress(request.getPickupAddress())
                .pickupLocation(location)
                .deliveryAddress(request.getDeliveryAddress())
                .deliveryLocation(deliveryLoc)
                .packageDescription(request.getPackageDescription())
                .packageValue(request.getPackageValue())
                .vehicleType(request.getVehicleType())
                .shippingCost(finalCost)
                .status(ShipmentStatus.WAITING_PAYMENT)
                .build();

        List<PackageImage> images = new ArrayList<>();
        List<String> uploadedUrls = new ArrayList<>();

        if (imageFiles != null && !imageFiles.isEmpty()) {
            for (MultipartFile file : imageFiles) {
                try {
                    String imageUrl = gcsStorageService.uploadPackageImage(file);
                    uploadedUrls.add(imageUrl);
                    images.add(PackageImage.builder().imageUrl(imageUrl).shipment(shipment).build());
                } catch (IOException e) {
                    log.error("Lỗi upload ảnh kiện hàng: {}", e.getMessage());
                    throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Lỗi kết nối bộ nhớ đám mây khi tải ảnh.");
                }
            }
            shipment.setPackageImages(images);
        }

        Shipment savedShipment = shipmentRepository.save(shipment);
        return mapToDTO(savedShipment);
    }


    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getHistoryBySender(Long senderId) {
        return shipmentRepository.findBySenderIdOrderByCreatedAtDesc(senderId)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ShipmentResponseDTO getShipmentDetail(Long id, Long requesterId) {
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        if (!shipment.getSenderId().equals(requesterId) &&
                (shipment.getDriverId() == null || !shipment.getDriverId().equals(requesterId))) {
            log.warn("Cảnh báo bảo mật: User {} cố gắng truy cập đơn hàng {}", requesterId, id);
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền truy cập thông tin đơn hàng này.");
        }

        return mapToDTO(shipment);
    }

    @Override
    @Transactional
    public void rateShipment(Long shipmentId, Long senderId, int rating) {
        Shipment shipment = shipmentRepository.findById(shipmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        if (!shipment.getSenderId().equals(senderId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền đánh giá đơn hàng này!");
        }

        if (shipment.getStatus() != ShipmentStatus.AT_WAREHOUSE && shipment.getStatus() != ShipmentStatus.DELIVERED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ được đánh giá khi đơn hàng đã hoàn tất!");
        }

        if (shipment.getRating() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đơn hàng này đã được đánh giá rồi!");
        }

        shipment.setRating(rating);
        shipmentRepository.save(shipment);

        int bonusPoints = rating * 10;

        if (shipment.getDriverId() != null) {
            try {
                userServiceClient.addPointsToDriver(shipment.getDriverId(), bonusPoints);
                log.info("Đã cộng {} điểm cho tài xế ID: {}", bonusPoints, shipment.getDriverId());
            } catch (Exception e) {
                log.error("Lỗi khi cộng điểm sang User Service: {}", e.getMessage());
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAvailableShipments() {
        return shipmentRepository.findByStatus(ShipmentStatus.PENDING)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ShipmentResponseDTO acceptShipment(Long shipmentId, Long driverId) {
        Shipment shipment = shipmentRepository.findById(shipmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        if (shipment.getStatus() != ShipmentStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Đơn hàng này đã bị hủy hoặc có người khác nhận!");
        }

        shipment.setDriverId(driverId);
        shipment.setStatus(ShipmentStatus.ACCEPTED);
        shipment.setAcceptedAt(LocalDateTime.now());

        Shipment updatedShipment = shipmentRepository.save(shipment);
        return mapToDTO(updatedShipment);
    }

    private static final BigDecimal BASE_PICKUP_REWARD = new BigDecimal("4000");
    private static final BigDecimal INCENTIVE_BONUS = new BigDecimal("500");
    private static final int INCENTIVE_THRESHOLD = 10;

    @Override
    @Transactional
    public ShipmentResponseDTO updateShipmentStatus(Long shipmentId, Long driverId, ShipmentStatus newStatus) {
        Shipment shipment = shipmentRepository.findById(shipmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        if (shipment.getDriverId() == null || !shipment.getDriverId().equals(driverId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền cập nhật đơn hàng này!");
        }

        validateStatusTransition(shipment.getStatus(), newStatus);

        if (shipment.getStatus() == ShipmentStatus.PICKED_UP && newStatus == ShipmentStatus.AT_WAREHOUSE) {
            processDriverReward(driverId, shipmentId);
        }

        shipment.setStatus(newStatus);
        shipment.setUpdatedAt(LocalDateTime.now());

        if (newStatus == ShipmentStatus.PICKED_UP) {
            shipment.setPickedUpAt(LocalDateTime.now());
        }

        if (newStatus == ShipmentStatus.DELIVERED) {
            try {
                if (shipment.getShippingCost() != null) {
                    int pointsEarned = shipment.getShippingCost().divide(new BigDecimal("1000")).intValue();
                    userServiceClient.addPointsToDriver(shipment.getSenderId(), pointsEarned);
                    log.info("Đã tự động cộng {} điểm cho khách hàng ID: {} từ đơn hàng {}", pointsEarned, shipment.getSenderId(), shipmentId);
                }
            } catch (Exception e) {
                log.error("Lỗi khi cộng điểm tích lũy cho khách hàng sang User Service: {}", e.getMessage());
            }
        }

        Shipment updatedShipment = shipmentRepository.save(shipment);
        return mapToDTO(updatedShipment);
    }

    private void processDriverReward(Long driverId, Long shipmentId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        long todayCount = shipmentRepository.countByDriverIdAndStatusAndUpdatedAtAfter(
                driverId, ShipmentStatus.AT_WAREHOUSE, startOfDay);

        BigDecimal finalReward = BASE_PICKUP_REWARD;
        String note = "Thưởng lấy hàng về kho";

        if (todayCount >= INCENTIVE_THRESHOLD) {
            finalReward = finalReward.add(INCENTIVE_BONUS);
            note += " (Thưởng năng suất 500đ)";
        }

        walletService.addMoneyForTask(driverId, shipmentId, finalReward, note);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAcceptedShipmentsByDriver(Long driverId) {
        return shipmentRepository.findByDriverIdAndStatus(driverId, ShipmentStatus.ACCEPTED)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAllShipments() {
        return shipmentRepository.findAll()
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public void autoRepublishStuckOrders() {
        System.out.println("🤖 [ROBOT] Đang kiểm tra các đơn hàng bị tài xế ngâm...");

        List<Shipment> allShipments = shipmentRepository.findAll();
        LocalDateTime tenMinutesAgo = LocalDateTime.now().minusMinutes(10);

        for (Shipment shipment : allShipments) {
            if (shipment.getStatus() == ShipmentStatus.PENDING &&
                    shipment.getCreatedAt() != null &&
                    shipment.getCreatedAt().isBefore(tenMinutesAgo)) {

                shipment.setCreatedAt(LocalDateTime.now());
                shipmentRepository.save(shipment);

                System.out.println("🚀 Đã nới bán kính tìm kiếm & Làm mới giờ cho đơn SH-" + shipment.getId() + " (KHÔNG TĂNG GIÁ!)");
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAvailableShipments(Double lat, Double lng) {
        if (lat == null || lng == null) {
            return shipmentRepository.findByStatus(ShipmentStatus.PENDING)
                    .stream()
                    .map(this::mapToDTO)
                    .collect(Collectors.toList());
        }
        return shipmentRepository.findAvailableShipmentsSortedByDistance(lat, lng)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public Shipment getShipmentById(Long id) {
        return shipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn hàng với ID: " + id));
    }

    @Override
    @Transactional
    public Shipment updateShipmentStatus(Long id, String status) {
        Shipment shipment = getShipmentById(id);
        try {
            shipment.setStatus(ShipmentStatus.valueOf(status.toUpperCase()));
            return shipmentRepository.save(shipment);
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Trạng thái đơn hàng truyền vào không hợp lệ!");
        }
    }

    @Override
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalOrders", shipmentRepository.count());
        stats.put("revenue", 15000000);
        return stats;
    }

    @Override
    public Map<String, Object> getLiveMonitoringData() {
        Map<String, Object> liveData = new HashMap<>();
        long movingOrders = shipmentRepository.findAll().stream()
                .filter(s -> s.getStatus() == ShipmentStatus.DELIVERING || s.getStatus() == ShipmentStatus.ACCEPTED)
                .count();

        liveData.put("movingOrders", movingOrders);
        liveData.put("onlineDrivers", 12);
        liveData.put("alerts", new ArrayList<>());
        liveData.put("mapData", new ArrayList<>());
        liveData.put("logs", new ArrayList<>());

        return liveData;
    }

    @Override
    public Shipment getLatestShipmentBySender(Long senderId) {
        return shipmentRepository.findFirstBySenderIdOrderByIdDesc(senderId)
                .orElse(null);
    }

    @Override
    public List<Shipment> getShipmentsBySender(Long senderId) {
        return shipmentRepository.findBySenderIdOrderByCreatedAtDesc(senderId);
    }

    private void validateStatusTransition(ShipmentStatus current, ShipmentStatus next) {
        if (current == ShipmentStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hãy dùng chức năng Nhận Đơn để cập nhật trạng thái PENDING.");
        }
        if (current == ShipmentStatus.ACCEPTED && next != ShipmentStatus.PICKED_UP) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái tiếp theo phải là LẤY HÀNG (PICKED_UP).");
        }
    }

    @Override
    public void notifyDriverArrivedAtPickup(Long shipmentId, Long driverId) {
        Shipment shipment = shipmentRepository.findById(shipmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        // Kiểm tra quyền: Chỉ tài xế đang nhận đơn này mới được bấm
        if (shipment.getDriverId() == null || !shipment.getDriverId().equals(driverId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền thao tác trên đơn hàng này!");
        }

        try {
            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            String notificationUrl = "http://localhost:8085/api/notifications/send";

            Map<String, Object> notifRequest = new HashMap<>();
            notifRequest.put("userId", shipment.getSenderId());
            notifRequest.put("title", "Tài xế đã đến nơi! 🛵");
            notifRequest.put("body", "Tài xế đã đến điểm lấy hàng cho đơn #" + shipmentId + ". Bạn vui lòng chuẩn bị hàng hóa để giao cho tài xế nhé!");
            notifRequest.put("topic", "USER_" + shipment.getSenderId());

            restTemplate.postForObject(notificationUrl, notifRequest, String.class);
            log.info("Đã bắn yêu cầu gửi thông báo 'Đến lấy hàng' cho khách ID: {}", shipment.getSenderId());
        } catch (Exception e) {
            log.error("Lỗi khi gọi Notification Service: {}", e.getMessage());
        }
    }


    private ShipmentResponseDTO mapToDTO(Shipment shipment) {
        List<String> imageUrls = shipment.getPackageImages().stream()
                .map(PackageImage::getImageUrl)
                .collect(Collectors.toList());

        String realSenderName = "Khách hàng";
        String realDriverName = "Tài xế";

        try {
            UserAuthDTO userDto = authServiceClient.getUserProfile(shipment.getSenderId());
            if (userDto != null && userDto.getFullName() != null) {
                realSenderName = userDto.getFullName();
            }

            if (shipment.getDriverId() != null) {
                UserAuthDTO driverDto = authServiceClient.getUserProfile(shipment.getDriverId());
                if (driverDto != null && driverDto.getFullName() != null) realDriverName = driverDto.getFullName();
            }
        } catch (Exception e) {
            log.warn("Không thể lấy thông tin tên cho user {}: {}", shipment.getSenderId(), e.getMessage());
        }

        return ShipmentResponseDTO.builder()
                .id(shipment.getId())
                .senderId(shipment.getSenderId())
                .senderName(realSenderName)
                .driverName(realDriverName)
                .driverId(shipment.getDriverId())
                .pickupAddress(shipment.getPickupAddress())
                .pickupLongitude(shipment.getPickupLocation() != null ? shipment.getPickupLocation().getX() : 0.0)
                .pickupLatitude(shipment.getPickupLocation() != null ? shipment.getPickupLocation().getY() : 0.0)
                .deliveryAddress(shipment.getDeliveryAddress())
                .deliveryLongitude(shipment.getDeliveryLocation() != null ? shipment.getDeliveryLocation().getX() : 0.0)
                .deliveryLatitude(shipment.getDeliveryLocation() != null ? shipment.getDeliveryLocation().getY() : 0.0)
                .packageDescription(shipment.getPackageDescription())
                .packageValue(shipment.getPackageValue())
                .vehicleType(shipment.getVehicleType())
                .shippingCost(shipment.getShippingCost())
                .status(shipment.getStatus())
                .createdAt(shipment.getCreatedAt())
                .imageUrls(imageUrls)
                .rating(shipment.getRating())
                .build();
    }
}