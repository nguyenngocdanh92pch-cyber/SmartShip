package vn.edu.shipmentservice.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "wallet_transaction")
@Data
public class WalletTransaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private Long driverId;
    private Long shipmentId;
    private BigDecimal amount;
    private String description;
    private LocalDateTime createdAt = LocalDateTime.now();
}
