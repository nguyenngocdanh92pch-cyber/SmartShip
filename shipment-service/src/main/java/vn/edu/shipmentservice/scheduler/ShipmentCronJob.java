package vn.edu.shipmentservice.scheduler;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import vn.edu.shipmentservice.service.ShipmentService;

@Component
@RequiredArgsConstructor
public class ShipmentCronJob {

    // Gọi đến interface thay vì gọi trực tiếp Repository
    private final ShipmentService shipmentService;

    // Robot chạy ngầm cứ mỗi 60 giây (60000 ms)
    @Scheduled(fixedRate = 60000)
    public void runAutoRepublishTask() {
        shipmentService.autoRepublishStuckOrders();
    }
}
