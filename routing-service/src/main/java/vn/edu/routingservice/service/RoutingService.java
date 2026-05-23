package vn.edu.routingservice.service;

//import com.google.maps.model.DirectionsRoute;

import java.math.BigDecimal;
import java.util.List;

public interface RoutingService {

    RouteEstimate calculateDistanceAndCost(double originLng, double originLat, double destLng, double destLat);

    DirectionsRoute optimizeDriverRoute(String coordinates);

    // Record cũ đã có
    record RouteEstimate(String distance, String duration, BigDecimal cost) {}

    // THÊM DÒNG NÀY VÀO ĐỂ SỬA LỖI:
    record DirectionsRoute(String message, String waypointsData) {}
}
