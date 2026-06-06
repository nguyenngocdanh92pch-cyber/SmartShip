package vn.edu.shipmentservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.shipmentservice.entity.DriverWallet;

@Repository
public interface DriverWalletRepository extends JpaRepository<DriverWallet, Long> {
}
