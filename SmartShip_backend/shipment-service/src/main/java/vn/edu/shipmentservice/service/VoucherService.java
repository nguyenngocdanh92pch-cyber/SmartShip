package vn.edu.shipmentservice.service;

import vn.edu.shipmentservice.entity.Voucher;
import java.util.List;

public interface VoucherService {
    Voucher createVoucher(Voucher voucher);
    List<Voucher> getAllVouchers();
}