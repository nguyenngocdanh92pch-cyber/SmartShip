package vn.edu.shipmentservice.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.shipmentservice.entity.Voucher;
import vn.edu.shipmentservice.repository.VoucherRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional; // THÊM THƯ VIỆN NÀY ĐỂ XỬ LÝ OPTIONAL

@RestController
@RequestMapping("/shipments/vouchers")
public class VoucherController {

    @Autowired
    private VoucherRepository voucherRepository;

    // =========================================================================
    // 🌟 1. Dành cho Web Admin: Lấy toàn bộ danh sách Voucher hiển thị lên bảng
    // =========================================================================
    @GetMapping
    public ResponseEntity<?> getAllVouchers() {
        try {
            List<Voucher> vouchers = voucherRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));
            return ResponseEntity.ok(vouchers);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Lỗi hệ thống khi lấy danh sách: " + e.getMessage());
        }
    }

    // =========================================================================
    // ➕ 2. Dành cho Web Admin: Tạo Voucher mới
    // =========================================================================
    @PostMapping("/create")
    public ResponseEntity<?> createVoucher(@RequestBody Voucher voucher) {
        if (voucherRepository.findByCode(voucher.getCode()).isPresent()) {
            return ResponseEntity.badRequest().body("Mã voucher này đã tồn tại trên hệ thống!");
        }
        voucher.setUsedCount(0);
        voucher.setIsActive(true);
        Voucher savedVoucher = voucherRepository.save(voucher);
        return ResponseEntity.ok(savedVoucher);
    }

    // =========================================================================
    // 📱 3. Dành cho Mobile App (Sender): Kiểm tra mã Voucher có hợp lệ không
    // =========================================================================
    @GetMapping("/validate/{code}")
    public ResponseEntity<?> validateVoucher(@PathVariable String code) {
        // 🚀 ĐÃ FIX: Trả về lỗi 400 thân thiện thay vì làm sập server (lỗi 500)
        Optional<Voucher> voucherOpt = voucherRepository.findByCode(code);
        if (voucherOpt.isEmpty()) {
            return ResponseEntity.badRequest().body("Mã voucher không tồn tại!");
        }

        Voucher voucher = voucherOpt.get();

        if (!voucher.getIsActive() || voucher.getValidUntil().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body("Mã voucher đã hết hạn hoặc bị khóa!");
        }
        if (voucher.getUsedCount() >= voucher.getUsageLimit()) {
            return ResponseEntity.badRequest().body("Mã voucher đã hết lượt sử dụng!");
        }

        return ResponseEntity.ok(voucher);
    }

    // =========================================================================
    // 📱 4. [THÊM MỚI] Dành cho Mobile App: Lấy danh sách Voucher Khả dụng
    // =========================================================================
    @GetMapping("/available")
    public ResponseEntity<?> getAvailableVouchers() {
        try {
            List<Voucher> availableVouchers = voucherRepository.findAvailableVouchers();
            return ResponseEntity.ok(availableVouchers);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Lỗi lấy voucher: " + e.getMessage());
        }
    }
}