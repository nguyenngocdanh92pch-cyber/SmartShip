package com.smartship.authservice.util;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtUtil {

    // Khóa bí mật (Trong thực tế nên cấu hình ở file application.yml)
    private static final String SECRET = "DayLaMotKhoaBiMatRatDaiVaBaoMatChoHeThongSmartShip123!@#";
    private static final long EXPIRATION_TIME = 86400000; // 24 giờ

    private Key getSignKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }

    public String generateToken(String phoneNumber, String role) {
        Map<String, Object> claims = new HashMap<>();
        // Đưa role vào payload để client hoặc gateway có thể giải mã và kiểm tra
        claims.put("role", role);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(phoneNumber)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(getSignKey(), SignatureAlgorithm.HS256)
                .compact();
    }
}