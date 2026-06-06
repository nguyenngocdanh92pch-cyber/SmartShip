package vn.edu.shipmentservice.service;

import vn.edu.shipmentservice.dto.EarningDashboardResponse;

public interface EarningService {
    // Sửa driverId thành kiểu Long cho khớp với Entity
    EarningDashboardResponse calculateEarnings(Long driverId, String period);
}
