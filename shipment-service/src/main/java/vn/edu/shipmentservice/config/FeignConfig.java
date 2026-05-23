package vn.edu.shipmentservice.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Configuration
public class FeignConfig implements RequestInterceptor {

    @Override
    public void apply(RequestTemplate template) {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();

            // 1. Lấy token bảo mật (Authorization) từ request của App Flutter
            String authorization = request.getHeader("Authorization");
            if (authorization != null) {
                template.header("Authorization", authorization);
            }

            // 2. Lấy thêm header X-User-Id (nếu API Gateway của bạn sử dụng)
            String xUserId = request.getHeader("X-User-Id");
            if (xUserId != null) {
                template.header("X-User-Id", xUserId);
            }
        }
    }
}