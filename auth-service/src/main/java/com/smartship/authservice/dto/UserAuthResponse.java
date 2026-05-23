package com.smartship.authservice.dto;

public class UserAuthResponse {
    private Long userId;
    private String fullName;

    // Constructors
    public UserAuthResponse() {}

    public UserAuthResponse(Long userId, String fullName) {
        this.userId = userId;
        this.fullName = fullName;
    }

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
}