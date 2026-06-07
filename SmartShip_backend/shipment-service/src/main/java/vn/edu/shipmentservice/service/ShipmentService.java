package vn.edu.shipmentservice.service;

import org.springframework.web.multipart.MultipartFile;
import vn.edu.shipmentservice.dto.ShipmentRequestDTO;
import vn.edu.shipmentservice.dto.ShipmentResponseDTO;
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;

import java.util.List;
import java.util.Map;

public interface ShipmentService {
    void notifyDriverArrivedAtPickup(Long shipmentId, Long driverId);
    // Tạo đơn hàng mới
    ShipmentResponseDTO createShipment(Long senderId, ShipmentRequestDTO request, List<MultipartFile> imageFiles, String voucherCode);
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


    // =========================================================
    // 🌟 PHẦN CODE GỘP THÊM TỪ BẠN CỦA BẠN (ADMIN/VOUCHER/DASHBOARD)
    // =========================================================

    // Hàm lấy chi tiết đơn hàng theo ID (trả về Entity nguyên thủy)
    Shipment getShipmentById(Long id);

    // Overload: Hàm cập nhật trạng thái đơn hàng bằng String (Dành cho admin duyệt đơn)
    Shipment updateShipmentStatus(Long id, String status);

    // Lấy dữ liệu tổng hợp phục vụ Admin Dashboard (Tổng doanh thu, số lượng đơn)
    Map<String, Object> getDashboardStats();

    // Lấy dữ liệu vận hành thời gian thực (Bản đồ giám sát Live Monitoring)
    Map<String, Object> getLiveMonitoringData();

    // Lấy đơn hàng mới nhất đang hoạt động của người gửi
    Shipment getLatestShipmentBySender(Long senderId);

    // Lấy toàn bộ danh sách lịch sử đơn hàng của người gửi (Trả về Entity)
    List<Shipment> getShipmentsBySender(Long senderId);
}