package vn.edu.shipmentservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.edu.shipmentservice.entity.WalletTransaction;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    // Lấy danh sách biến động số dư của tài xế trong ngày/tuần/tháng
    @Query("SELECT t FROM WalletTransaction t WHERE t.driverId = :driverId " +
            "AND t.createdAt >= :startDate AND t.createdAt <= :endDate")
    List<WalletTransaction> findTransactionsByPeriod(
            @Param("driverId") Long driverId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);
    List<WalletTransaction> findByDriverIdOrderByCreatedAtDesc(Long driverId);
}