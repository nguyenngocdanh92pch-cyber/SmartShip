package com.smartship.authservice.dto;

import lombok.*;

@Data
@Getter
@Setter
public class UpdateProfileRequest {
    private String fullName;
    private String phone;
}
