package vn.edu.shipmentservice.service;

import vn.edu.shipmentservice.dto.EarningDashboardResponse;

public interface EarningService {
    EarningDashboardResponse calculateEarnings(Long driverId, String period);
}
