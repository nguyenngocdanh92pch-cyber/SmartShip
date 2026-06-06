package vn.edu.shipmentservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import vn.edu.shipmentservice.config.FeignConfig;
import vn.edu.shipmentservice.dto.UserAuthDTO;

// Đổi "auth-service" thành tên service của bạn đăng ký trên Eureka,
// hoặc dùng url = "http://localhost:xxxx" (cổng của Auth Service)
@FeignClient(name = "auth-service", url = "http://localhost:8081", configuration = FeignConfig.class)
public interface AuthServiceClient {

    // CHÚ Ý: Thay đổi đường dẫn này cho khớp với API lấy thông tin User bên Auth Service của bạn
    @GetMapping("/users/{id}/profile")
    UserAuthDTO getUserProfile(@PathVariable("id") Long id);

}

