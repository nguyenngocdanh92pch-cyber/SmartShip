package vn.edu.shipmentservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

// 🌟 Trỏ thẳng hàng tới cổng 8082 của User Service
@FeignClient(name = "user-service", url = "http://localhost:8082")
public interface UserServiceClient {

    @PostMapping("/users/{userId}/add-points")
    void addPointsToDriver(@PathVariable("userId") Long userId, @RequestParam("points") int points);
}