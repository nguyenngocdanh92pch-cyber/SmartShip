package vn.edu.shipmentservice.service;

import java.math.BigDecimal;

public interface WalletService {
    void addMoneyForTask(Long driverId, Long shipmentId, BigDecimal amount, String description);
    boolean withdrawMoney(Long driverId, BigDecimal amount, String bankInfo);
}