package vn.edu.shipmentservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EarningDashboardResponse {
    private double totalEarnings;
    private int totalDeliveries;
    private double tipsEarned;
    private String hoursOnline;
    private List<ChartPoint> chartData;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ChartPoint {
        private String label;
        private double value;
    }
}
