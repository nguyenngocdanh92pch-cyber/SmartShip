package vn.edu.shipmentservice.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.edu.shipmentservice.dto.EarningDashboardResponse;
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;
import vn.edu.shipmentservice.entity.WalletTransaction;
import vn.edu.shipmentservice.repository.ShipmentRepository;
import vn.edu.shipmentservice.repository.WalletTransactionRepository;
import vn.edu.shipmentservice.service.EarningService;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EarningServiceImpl implements EarningService {

    // Inject cả 2 Repository để lấy Số đơn (Shipment) và Lấy Tiền (WalletTransaction)
    private final ShipmentRepository shipmentRepository;
    private final WalletTransactionRepository transactionRepository;

    @Override
    public EarningDashboardResponse calculateEarnings(Long driverId, String period) {
        LocalDateTime startDate;
        LocalDateTime endDate = LocalDateTime.now();

        switch (period.toLowerCase()) {
            case "weekly":
                startDate = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).atStartOfDay();
                break;
            case "monthly":
                startDate = LocalDate.now().with(TemporalAdjusters.firstDayOfMonth()).atStartOfDay();
                break;
            case "daily":
            default:
                startDate = LocalDate.now().atStartOfDay();
                break;
        }

        // 1. Kéo Dữ liệu Chuyến xe (Để tính Giờ hoạt động & Số đơn)
        List<Shipment> shipments = shipmentRepository.findCompletedByDriverInPeriod(driverId, ShipmentStatus.DELIVERED, startDate, endDate);

        // 2. Kéo Lịch sử Giao dịch Ví (Để tính Tổng tiền & Vẽ biểu đồ)
        List<WalletTransaction> transactions = transactionRepository.findTransactionsByPeriod(driverId, startDate, endDate);

        EarningDashboardResponse response = new EarningDashboardResponse();

        // 🌟 TÍNH TOÁN DỰA TRÊN WALLET TRANSACTION
        double totalEarnings = transactions.stream()
                .mapToDouble(t -> t.getAmount() != null ? t.getAmount().doubleValue() : 0.0)
                .sum();

        // 🌟 TÍNH TOÁN DỰA TRÊN SHIPMENT
        int totalDeliveries = shipments.size();

        response.setTotalEarnings(totalEarnings);
        response.setTotalDeliveries(totalDeliveries);
        response.setTipsEarned(0.0); // Chưa có hệ thống Tip, tạm để 0
        response.setHoursOnline(calculateEstimatedOnlineHours(shipments));

        // Vẽ biểu đồ dựa trên Lịch sử biến động ví thay vì Shipment
        response.setChartData(buildChartData(transactions, period));

        return response;
    }

    // --- HÀM VẼ BIỂU ĐỒ (Dùng dữ liệu từ WalletTransaction) ---
    private List<EarningDashboardResponse.ChartPoint> buildChartData(List<WalletTransaction> transactions, String period) {
        List<EarningDashboardResponse.ChartPoint> points = new ArrayList<>();
        if (transactions.isEmpty()) return points;

        if (period.equalsIgnoreCase("daily")) {
            Map<Integer, Double> hourlyEarnings = transactions.stream()
                    .collect(Collectors.groupingBy(
                            t -> t.getCreatedAt().getHour(), // Dùng thời gian giao dịch của ví
                            Collectors.summingDouble(t -> t.getAmount() != null ? t.getAmount().doubleValue() : 0.0)
                    ));

            hourlyEarnings.forEach((hour, amount) -> {
                points.add(new EarningDashboardResponse.ChartPoint(String.format("%02d:00", hour), amount));
            });
            points.sort((p1, p2) -> p1.getLabel().compareTo(p2.getLabel()));

        } else if (period.equalsIgnoreCase("weekly")) {
            Map<DayOfWeek, Double> dailyEarnings = transactions.stream()
                    .collect(Collectors.groupingBy(
                            t -> t.getCreatedAt().getDayOfWeek(),
                            Collectors.summingDouble(t -> t.getAmount() != null ? t.getAmount().doubleValue() : 0.0)
                    ));

            dailyEarnings.forEach((day, amount) -> {
                points.add(new EarningDashboardResponse.ChartPoint(day.name(), amount));
            });

        } else {
            Map<Integer, Double> monthlyEarnings = transactions.stream()
                    .collect(Collectors.groupingBy(
                            t -> t.getCreatedAt().getDayOfMonth(),
                            Collectors.summingDouble(t -> t.getAmount() != null ? t.getAmount().doubleValue() : 0.0)
                    ));

            monthlyEarnings.forEach((day, amount) -> {
                points.add(new EarningDashboardResponse.ChartPoint("Ngày " + day, amount));
            });
            points.sort((p1, p2) -> Integer.compare(
                    Integer.parseInt(p1.getLabel().replace("Ngày ", "")),
                    Integer.parseInt(p2.getLabel().replace("Ngày ", ""))
            ));
        }

        return points;
    }

    // --- HÀM TÍNH GIỜ (Vẫn giữ nguyên dùng dữ liệu Shipment) ---
    private String calculateEstimatedOnlineHours(List<Shipment> shipments) {
        if (shipments == null || shipments.isEmpty()) return "0h 0m";

        LocalDateTime first = shipments.stream()
                .map(s -> s.getAcceptedAt() != null ? s.getAcceptedAt() : s.getUpdatedAt())
                .min(LocalDateTime::compareTo).orElse(LocalDateTime.now());

        LocalDateTime last = shipments.stream()
                .map(Shipment::getUpdatedAt)
                .max(LocalDateTime::compareTo).orElse(LocalDateTime.now());

        long minutesBetween = java.time.Duration.between(first, last).toMinutes();
        if (minutesBetween <= 0) return "0h 30m";

        long hours = minutesBetween / 60;
        long mins = minutesBetween % 60;
        return hours + "h " + mins + "m";
    }
}