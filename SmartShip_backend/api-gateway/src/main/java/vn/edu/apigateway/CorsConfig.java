package vn.edu.apigateway; // Tui đã sửa lại cho đúng với thư mục bạn đang đặt file

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import java.util.Arrays;

@Configuration
public class CorsConfig {

    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration config = new CorsConfiguration();

        // 1. Cho phép trang React của bạn
        config.setAllowedOrigins(Arrays.asList("http://localhost:5173"));

        // 2. Cho phép tất cả các phương thức (GET, POST, PUT, DELETE,...)
        config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));

        // 3. Cho phép tất cả các Header
        config.setAllowedHeaders(Arrays.asList("*"));

        // 4. Cho phép gửi thông tin xác thực (Cookie, Token)
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return new CorsWebFilter(source);
    }
}