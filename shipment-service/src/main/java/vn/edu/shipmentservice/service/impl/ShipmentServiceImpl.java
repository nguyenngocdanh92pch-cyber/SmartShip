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
import vn.edu.shipmentservice.service.GcsStorageService;
import vn.edu.shipmentservice.service.ShipmentService;
import vn.edu.shipmentservice.service.WalletService;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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
    private UserServiceClient userServiceClient; // Thêm dòng này


    @Override
    @Transactional
    public ShipmentResponseDTO createShipment(Long senderId, ShipmentRequestDTO request, List<MultipartFile> imageFiles) {
        RoutingServiceClient.RouteEstimateDTO estimate = routingServiceClient.getEstimate(
                request.getPickupLongitude(),
                request.getPickupLatitude(),
                request.getDeliveryLongitude(),
                request.getDeliveryLatitude()
        );

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
                .shippingCost(estimate.cost())
                .status(ShipmentStatus.PENDING)
                .build();

        List<PackageImage> images = new ArrayList<>();
        List<String> uploadedUrls = new ArrayList<>(); // Tracking URL để dọn rác nếu lỗi

        if (imageFiles != null && !imageFiles.isEmpty()) {
            for (MultipartFile file : imageFiles) {
                try {
                    String imageUrl = gcsStorageService.uploadPackageImage(file);
                    uploadedUrls.add(imageUrl); // Lưu tạm URL vừa up thành công
                    images.add(PackageImage.builder().imageUrl(imageUrl).shipment(shipment).build());
                } catch (IOException e) {
                    log.error("Lỗi upload ảnh kiện hàng: {}", e.getMessage());
                    // TODO: Gọi hàm gcsStorageService.deleteImages(uploadedUrls) để xóa các ảnh đã up trước đó
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

    // FIX LỖI IDOR: Thêm tham số requesterId (ID của người đang gọi API được giải mã từ Token)
    @Override
    @Transactional(readOnly = true)
    public ShipmentResponseDTO getShipmentDetail(Long id, Long requesterId) {
        Shipment shipment = shipmentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));

        // Xác thực quyền sở hữu: Chỉ Người Gửi hoặc Tài Xế nhận đơn mới được xem chi tiết
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

        // 1. Kiểm tra quyền
        if (!shipment.getSenderId().equals(senderId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền đánh giá đơn hàng này!");
        }

        // 2. Chỉ cho đánh giá khi đã xong
        if (shipment.getStatus() != ShipmentStatus.AT_WAREHOUSE && shipment.getStatus() != ShipmentStatus.DELIVERED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ được đánh giá khi đơn hàng đã hoàn tất!");
        }

        // 3. ĐẢM BẢO CHỈ ĐÁNH GIÁ 1 LẦN
        if (shipment.getRating() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đơn hàng này đã được đánh giá rồi!");
        }

        // 4. Lưu mức sao vào DB Shipment
        shipment.setRating(rating);
        shipmentRepository.save(shipment);

        // 5. Tính điểm (Ví dụ: 1 sao = 10đ, 5 sao = 50đ)
        int bonusPoints = rating * 10;

        // 6. Bắn API sang User Service để lưu điểm cho Tài xế
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

    // Gộp luồng nhận đơn vào duy nhất hàm này để tránh phân mảnh code
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

    // Hàm update trạng thái chỉ dành cho các thao tác SAU KHI nhận đơn
    // Các hằng số cấu hình thưởng
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

        // 1. Kiểm tra State Machine: Chặn nhảy cóc trạng thái
        validateStatusTransition(shipment.getStatus(), newStatus);

        // 2. Logic Trả lương: Khi trạng thái chuẩn bị đổi từ PICKED_UP sang AT_WAREHOUSE
        if (shipment.getStatus() == ShipmentStatus.PICKED_UP && newStatus == ShipmentStatus.AT_WAREHOUSE) {
            processDriverReward(driverId, shipmentId);
        }

        // 3. Cập nhật trạng thái và các mốc thời gian
        shipment.setStatus(newStatus);
        shipment.setUpdatedAt(LocalDateTime.now()); // Quan trọng: Để hàm đếm đơn trong ngày hoạt động đúng

        if (newStatus == ShipmentStatus.PICKED_UP) {
            shipment.setPickedUpAt(LocalDateTime.now());
        }

        Shipment updatedShipment = shipmentRepository.save(shipment);
        return mapToDTO(updatedShipment);
    }

    // Tách riêng logic tính tiền để tuân thủ Clean Code (Single Responsibility)
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
        // Tìm tất cả các đơn hàng mà tài xế này đã nhận (Trạng thái ACCEPTED)
        return shipmentRepository.findByDriverIdAndStatus(driverId, ShipmentStatus.ACCEPTED)
                .stream()
                .map(this::mapToDTO) // Tận dụng lại hàm mapToDTO có sẵn của bạn
                .collect(Collectors.toList());
    }

    // --- PRIVATE HELPERS ---

    // Hàm đảm bảo luồng đi đơn hàng hợp lệ
    private void validateStatusTransition(ShipmentStatus current, ShipmentStatus next) {
        if (current == ShipmentStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hãy dùng chức năng Nhận Đơn để cập nhật trạng thái PENDING.");
        }
        if (current == ShipmentStatus.ACCEPTED && next != ShipmentStatus.PICKED_UP) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái tiếp theo phải là LẤY HÀNG (PICKED_UP).");
        }
        // TODO: Mở rộng thêm luồng PICKED_UP -> IN_TRANSIT -> AT_WAREHOUSE tùy theo logic của ứng dụng.
    }

    private ShipmentResponseDTO mapToDTO(Shipment shipment) {
        List<String> imageUrls = shipment.getPackageImages().stream()
                .map(PackageImage::getImageUrl)
                .collect(Collectors.toList());

        // Mặc định nếu không lấy được tên thì hiển thị "Khách hàng"
        String realSenderName = "Khách hàng";
        String realDriverName = "Tài xế";

        try {
            // Gọi sang Auth Service để lấy thông tin
            UserAuthDTO userDto = authServiceClient.getUserProfile(shipment.getSenderId());
            if (userDto != null && userDto.getFullName() != null) {
                realSenderName = userDto.getFullName();
            }

            if (shipment.getDriverId() != null) {
                UserAuthDTO driverDto = authServiceClient.getUserProfile(shipment.getDriverId());
                if (driverDto != null && driverDto.getFullName() != null) realDriverName = driverDto.getFullName();
            }
        } catch (Exception e) {
            // Dùng try-catch để lỡ Auth Service có bị sập thì Shipment Service vẫn chạy bình thường
            log.warn("Không thể lấy thông tin tên cho user {}: {}", shipment.getSenderId(), e.getMessage());
        }

        return ShipmentResponseDTO.builder()
                .id(shipment.getId())
                .senderId(shipment.getSenderId())
                .senderName(realSenderName) // 🌟 TRUYỀN TÊN VỪA LẤY ĐƯỢC VÀO ĐÂY
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
                .shippingCost(shipment.getShippingCost())
                .status(shipment.getStatus())
                .createdAt(shipment.getCreatedAt())
                .imageUrls(imageUrls)
                .rating(shipment.getRating())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAllShipments() {
        return shipmentRepository.findAll()
                .stream()
                .map(this::mapToDTO) // Hàm mapToDTO đã có sẵn trong class này
                .collect(Collectors.toList());
    }

    @Override
    public void autoRepublishStuckOrders() {
        System.out.println("🤖 [ROBOT] Đang kiểm tra các đơn hàng bị tài xế ngâm...");

        List<Shipment> allShipments = shipmentRepository.findAll();

        // Mốc thời gian 10 phút (Nếu để lâu hơn 10 phút mà status vẫn PENDING)
        LocalDateTime tenMinutesAgo = LocalDateTime.now().minusMinutes(10);

        for (Shipment shipment : allShipments) {
            if (shipment.getStatus() == ShipmentStatus.PENDING &&
                    shipment.getCreatedAt() != null &&
                    shipment.getCreatedAt().isBefore(tenMinutesAgo)) {

                // 1. TUYỆT ĐỐI KHÔNG TĂNG TIỀN (Giữ nguyên shippingCost)

                // 2. Refresh lại thời gian tạo đơn để nó "trồi" lên đầu danh sách hiển thị
                shipment.setCreatedAt(LocalDateTime.now());

                // 3. Cập nhật lại vào DB
                shipmentRepository.save(shipment);

                System.out.println("🚀 Đã nới bán kính tìm kiếm & Làm mới giờ cho đơn SH-" + shipment.getId() + " (KHÔNG TĂNG GIÁ!)");
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ShipmentResponseDTO> getAvailableShipments(Double lat, Double lng) {
        // Nếu không truyền tọa độ (hoặc lỗi GPS), trả về danh sách mặc định
        if (lat == null || lng == null) {
            return shipmentRepository.findByStatus(ShipmentStatus.PENDING)
                    .stream()
                    .map(this::mapToDTO)
                    .collect(Collectors.toList());
        }

        // 🌟 Gọi hàm query sắp xếp theo khoảng cách thực tế
        return shipmentRepository.findAvailableShipmentsSortedByDistance(lat, lng)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }
}