package vn.edu.shipmentservice.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "driver_wallet")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverWallet {
    @Id
    private Long driverId;
    private BigDecimal balance;
    private LocalDateTime lastUpdated;
}
