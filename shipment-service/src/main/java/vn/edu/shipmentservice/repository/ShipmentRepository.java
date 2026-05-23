package vn.edu.shipmentservice.repository;


import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Repository
public interface ShipmentRepository extends JpaRepository<Shipment, Long> {
    // Tìm danh sách đơn hàng theo người gửi [cite: 130]
    List<Shipment> findBySenderIdOrderByCreatedAtDesc(Long senderId);
    List<Shipment> findByStatus(ShipmentStatus status);
    long countByDriverIdAndStatusAndUpdatedAtAfter(Long driverId, ShipmentStatus status, LocalDateTime startOfDay);
    List<Shipment> findByDriverIdAndStatus(Long driverId, ShipmentStatus status);

    @Query("SELECT s FROM Shipment s WHERE s.driverId = :driverId " +
            "AND s.status = 'AT_WAREHOUSE' " + // Chú ý: Hãy sửa chữ 'COMPLETED' thành trạng thái giao xong trong ShipmentStatus của bạn nhé
            "AND s.updatedAt >= :startDate AND s.updatedAt <= :endDate")
    List<Shipment> findCompletedByDriverInPeriod(
            @Param("driverId") Long driverId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);
    // =========================================================
    // API CŨ: DÀNH CHO DASHBOARD TỔNG QUAN
    // =========================================================
    @Query("SELECT COUNT(s) as count, SUM(s.shippingCost) as revenue FROM Shipment s " +
            "WHERE s.createdAt >= :start AND s.createdAt < :end")
    Map<String, Object> getStatsBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query(value = "SELECT EXTRACT(HOUR FROM created_at) as hour, COUNT(*) as count " +
            "FROM shipments WHERE created_at >= CURRENT_DATE " +
            "GROUP BY hour ORDER BY hour", nativeQuery = true)
    List<Map<String, Object>> getHourlyStatsToday();

    List<Shipment> findTop5ByOrderByCreatedAtDesc();

    // =========================================================
    // API MỚI: CÁC HÀM THỐNG KÊ CHO TRANG BÁO CÁO (ANALYTICS)
    // =========================================================

    // 1. Tổng doanh thu từ các đơn thành công (DELIVERED)
    @Query("SELECT COALESCE(SUM(s.shippingCost), 0) FROM Shipment s WHERE s.status = 'DELIVERED'")
    java.math.BigDecimal getTotalRevenue();

    // 2. Đếm số đơn theo trạng thái (DELIVERED)
    @Query("SELECT COUNT(s) FROM Shipment s WHERE s.status = 'DELIVERED'")
    Long countCompletedOrders();

    // 3. Biểu đồ doanh thu 7 ngày gần nhất
    @Query(value = "SELECT TO_CHAR(DATE(created_at), 'DD/MM') as date, SUM(shipping_cost) as revenue " +
            "FROM shipments " +
            "WHERE status = 'DELIVERED' AND created_at >= CURRENT_DATE - INTERVAL '7 days' " +
            "GROUP BY DATE(created_at) " +
            "ORDER BY DATE(created_at)", nativeQuery = true)
    List<Map<String, Object>> getRevenueChartData();

    // 4. Biểu đồ khung giờ cao điểm
    @Query(value = "SELECT EXTRACT(HOUR FROM created_at) as hour, COUNT(id) as orders " +
            "FROM shipments " +
            "GROUP BY hour " +
            "ORDER BY hour", nativeQuery = true)
    List<Map<String, Object>> getPeakHourChartData();

    // 5. Đếm thực tế loại xe từ Database (ĐÃ FIX: Chỉ đếm xe của các đơn DELIVERED)
    @Query("SELECT s.vehicleType as name, COUNT(s) as value FROM Shipment s WHERE s.vehicleType IS NOT NULL AND s.status = 'DELIVERED' GROUP BY s.vehicleType")
    List<Map<String, Object>> getVehicleDistribution();

    // 6. Đếm số đơn bị hủy
    @Query("SELECT COUNT(s) FROM Shipment s WHERE s.status = 'CANCELLED'")
    Long countCancelledOrders();

    @Query(value = "SELECT * FROM shipments s WHERE s.status = 'PENDING' " +
            "ORDER BY ST_Distance(s.pickup_location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)) ASC",
            nativeQuery = true)
    List<Shipment> findAvailableShipmentsSortedByDistance(@Param("lat") double lat, @Param("lng") double lng);
}
