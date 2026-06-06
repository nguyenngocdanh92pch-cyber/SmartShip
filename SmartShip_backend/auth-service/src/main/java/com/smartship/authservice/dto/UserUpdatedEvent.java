package com.smartship.authservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserUpdatedEvent implements Serializable {
    private Long userId;
    private String fullName;
    private String phone;
}
