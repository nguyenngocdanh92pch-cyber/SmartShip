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
import java.util.Optional;

@Repository
public interface ShipmentRepository extends JpaRepository<Shipment, Long> {
    List<Shipment> findBySenderIdOrderByCreatedAtDesc(Long senderId);
    List<Shipment> findByStatus(ShipmentStatus status);
    long countByDriverIdAndStatusAndUpdatedAtAfter(Long driverId, ShipmentStatus status, LocalDateTime startOfDay);
    List<Shipment> findByDriverIdAndStatus(Long driverId, ShipmentStatus status);

    Optional<Shipment> findFirstBySenderIdOrderByIdDesc(Long senderId);

    @Query("SELECT s FROM Shipment s WHERE s.driverId = :driverId " +
            "AND s.status = :status " +
            "AND s.updatedAt >= :startDate AND s.updatedAt <= :endDate")
    List<Shipment> findCompletedByDriverInPeriod(
            @Param("driverId") Long driverId,
            @Param("status") ShipmentStatus status,
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

    @Query("SELECT COALESCE(SUM(s.shippingCost), 0) FROM Shipment s WHERE s.status = vn.edu.shipmentservice.entity.ShipmentStatus.DELIVERED")
    java.math.BigDecimal getTotalRevenue();

    @Query("SELECT COUNT(s) FROM Shipment s WHERE s.status = vn.edu.shipmentservice.entity.ShipmentStatus.DELIVERED")
    Long countCompletedOrders();

    @Query(value = "SELECT TO_CHAR(DATE(created_at), 'DD/MM') as date, SUM(shipping_cost) as revenue " +
            "FROM shipments " +
            "WHERE status = 'DELIVERED' AND created_at >= CURRENT_DATE - INTERVAL '7 days' " +
            "GROUP BY DATE(created_at) " +
            "ORDER BY DATE(created_at)", nativeQuery = true)
    List<Map<String, Object>> getRevenueChartData();

    @Query(value = "SELECT EXTRACT(HOUR FROM created_at) as hour, COUNT(id) as orders " +
            "FROM shipments " +
            "GROUP BY hour " +
            "ORDER BY hour", nativeQuery = true)
    List<Map<String, Object>> getPeakHourChartData();

    @Query("SELECT s.vehicleType as name, COUNT(s) as value FROM Shipment s WHERE s.vehicleType IS NOT NULL AND s.status = vn.edu.shipmentservice.entity.ShipmentStatus.DELIVERED GROUP BY s.vehicleType")
    List<Map<String, Object>> getVehicleDistribution();

    @Query("SELECT COUNT(s) FROM Shipment s WHERE s.status = vn.edu.shipmentservice.entity.ShipmentStatus.CANCELLED")
    Long countCancelledOrders();

    @Query(value = "SELECT * FROM shipments s WHERE s.status = 'PENDING' " +
            "ORDER BY ST_Distance(s.pickup_location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)) ASC",
            nativeQuery = true)
    List<Shipment> findAvailableShipmentsSortedByDistance(@Param("lat") double lat, @Param("lng") double lng);
}