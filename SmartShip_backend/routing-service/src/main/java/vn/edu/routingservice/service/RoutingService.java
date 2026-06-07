package vn.edu.routingservice.service;

//import com.google.maps.model.DirectionsRoute;

import java.math.BigDecimal;
import java.util.List;

public interface RoutingService {

    RouteEstimate calculateDistanceAndCost(double originLng, double originLat, double destLng, double destLat, String vehicleType);

    DirectionsRoute optimizeDriverRoute(String coordinates);

    record RouteEstimate(String distance, String duration, BigDecimal cost) {}

    record DirectionsRoute(String message, String waypointsData) {}

    RouteEstimate calculateDistanceForDriver(double originLng, double originLat, double destLng, double destLat);
}
