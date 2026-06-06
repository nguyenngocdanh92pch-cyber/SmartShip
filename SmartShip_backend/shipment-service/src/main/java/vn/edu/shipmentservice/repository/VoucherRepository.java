package vn.edu.shipmentservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.shipmentservice.entity.Voucher;
import java.util.Optional;
import org.springframework.data.jpa.repository.Query; // THÊM IMPORT NÀY
import java.util.List;

@Repository
public interface VoucherRepository extends JpaRepository<Voucher, Long> {

    // Tìm Voucher dựa vào mã code (VD: tìm mã CUOITUAN20K)
    Optional<Voucher> findByCode(String code);

    // 🌟 THÊM DÒNG NÀY: Tìm các Voucher hợp lệ (Đang bật + Còn hạn + Còn lượt)
    @Query("SELECT v FROM Voucher v WHERE v.isActive = true AND v.validUntil > CURRENT_TIMESTAMP AND v.usedCount < v.usageLimit ORDER BY v.discountAmount DESC")
    List<Voucher> findAvailableVouchers();
}