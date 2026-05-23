package vn.edu.shipmentservice.dto;

import lombok.Data;

@Data
public class UserAuthDTO {
    private Long userId;
    private String fullName; // Biến này sẽ map với fullName từ Auth Service trả về
}