package vn.edu.shipmentservice.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.edu.shipmentservice.entity.Voucher;
import vn.edu.shipmentservice.repository.VoucherRepository;
import vn.edu.shipmentservice.service.VoucherService;
import java.util.List;

@Service
@RequiredArgsConstructor
public class VoucherServiceImpl implements VoucherService {

    private final VoucherRepository voucherRepository;

    @Override
    public Voucher createVoucher(Voucher voucher) {
        return voucherRepository.save(voucher);
    }

    @Override
    public List<Voucher> getAllVouchers() {
        // Lấy tất cả voucher để hiển thị lên bảng React
        return voucherRepository.findAll();
    }
}