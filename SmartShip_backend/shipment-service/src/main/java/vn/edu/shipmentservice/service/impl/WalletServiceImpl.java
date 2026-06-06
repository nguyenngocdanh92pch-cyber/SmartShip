package vn.edu.shipmentservice.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.shipmentservice.entity.DriverWallet;
import vn.edu.shipmentservice.entity.WalletTransaction;
import vn.edu.shipmentservice.repository.DriverWalletRepository;
import vn.edu.shipmentservice.repository.WalletTransactionRepository;
import vn.edu.shipmentservice.service.WalletService;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class WalletServiceImpl implements WalletService {

    private final DriverWalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;

    @Override
    @Transactional
    public void addMoneyForTask(Long driverId, Long shipmentId, BigDecimal amount, String description) {
        // 1. Tìm hoặc tạo ví mới
        DriverWallet wallet = walletRepository.findById(driverId)
                .orElse(DriverWallet.builder().driverId(driverId).balance(BigDecimal.ZERO).build());

        // 2. Cộng tiền
        wallet.setBalance(wallet.getBalance().add(amount));
        wallet.setLastUpdated(LocalDateTime.now());
        walletRepository.save(wallet);

        // 3. Ghi log lịch sử giao dịch
        WalletTransaction tx = new WalletTransaction();
        tx.setDriverId(driverId);
        tx.setShipmentId(shipmentId);
        tx.setAmount(amount);
        tx.setDescription(description);
        transactionRepository.save(tx);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional
    public boolean withdrawMoney(Long driverId, java.math.BigDecimal amount, String bankInfo) {
        // 1. Lấy ví của tài xế ra
        DriverWallet wallet = walletRepository.findById(driverId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy ví của tài xế!"));

        // 2. Kiểm tra số dư có đủ để rút không
        if (wallet.getBalance().compareTo(amount) < 0) {
            return false; // Thất bại: Không đủ tiền
        }

        // 3. Trừ tiền và cập nhật Ví
        wallet.setBalance(wallet.getBalance().subtract(amount));
        wallet.setLastUpdated(java.time.LocalDateTime.now());
        walletRepository.save(wallet);

        // 4. Ghi log lịch sử giao dịch (Lưu số ÂM để dễ đối soát)
        vn.edu.shipmentservice.entity.WalletTransaction tx = new WalletTransaction();
        tx.setDriverId(driverId);
        tx.setShipmentId(null); // Rút tiền thì không gắn với đơn hàng nào cả
        tx.setAmount(amount.negate()); // CHÚ Ý: .negate() để biến tiền dương thành tiền âm
        tx.setDescription("Rút tiền về ngân hàng: " + bankInfo);
        transactionRepository.save(tx);

        return true; // Thành công
    }
}