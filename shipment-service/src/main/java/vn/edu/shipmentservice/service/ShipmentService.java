package vn.edu.shipmentservice.service;


import org.springframework.web.multipart.MultipartFile;
import vn.edu.shipmentservice.dto.ShipmentRequestDTO;
import vn.edu.shipmentservice.dto.ShipmentResponseDTO;
import vn.edu.shipmentservice.entity.ShipmentStatus;

import java.util.List;

public interface ShipmentService {

    // Tạo đơn hàng mới
// Sửa thành như thế này:
    ShipmentResponseDTO createShipment(Long senderId, ShipmentRequestDTO request, List<MultipartFile> imageFiles);
    // Lấy lịch sử đơn hàng của người gửi
    List<ShipmentResponseDTO> getHistoryBySender(Long senderId);

    // Cập nhật trạng thái đơn hàng (dành cho tài xế)
    ShipmentResponseDTO updateShipmentStatus(Long shipmentId, Long driverId, ShipmentStatus newStatus);

    ShipmentResponseDTO getShipmentDetail(Long id, Long requesterId);

    List<ShipmentResponseDTO> getAcceptedShipmentsByDriver(Long driverId);

    void rateShipment(Long shipmentId, Long senderId, int rating);

    List<ShipmentResponseDTO> getAvailableShipments();

    ShipmentResponseDTO acceptShipment(Long shipmentId, Long driverId);

    void autoRepublishStuckOrders();

    List<ShipmentResponseDTO> getAvailableShipments(Double lat, Double lng);

    List<ShipmentResponseDTO> getAllShipments();
}
