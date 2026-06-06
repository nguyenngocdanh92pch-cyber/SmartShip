package vn.edu.shipmentservice.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate; // 🌟 THÊM THƯ VIỆN NÀY
import vn.edu.shipmentservice.entity.Shipment;
import vn.edu.shipmentservice.entity.ShipmentStatus;
import vn.edu.shipmentservice.repository.ShipmentRepository;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.*;

@RestController
// Sửa thành như vầy để đi ké cổng API Gateway của shipment-service
@RequestMapping("/shipments/payments")
public class PaymentController {

    @Value("${vnpay.tmnCode}")
    private String vnp_TmnCode;
    @Value("${vnpay.hashSecret}")
    private String secretKey;
    @Value("${vnpay.payUrl}")
    private String vnp_PayUrl;
    @Value("${vnpay.returnUrl}")
    private String vnp_ReturnUrl;

    @Autowired
    private ShipmentRepository shipmentRepository;

    // =========================================================================
    // 1. API CHO FLUTTER GỌI ĐỂ LẤY LINK MỞ TRÌNH DUYỆT VNPAY
    // =========================================================================
    @GetMapping("/create-url")
    public ResponseEntity<String> createPaymentUrl(@RequestParam Long shipmentId, @RequestParam long amount) throws Exception {
        String vnp_Version = "2.1.0";
        String vnp_Command = "pay";
        String orderType = "other";
        long amountInVNPayFormat = amount * 100; // VNPay yêu cầu nhân 100

        String vnp_TxnRef = shipmentId + "_" + System.currentTimeMillis();

        Map<String, String> vnp_Params = new HashMap<>();
        vnp_Params.put("vnp_Version", vnp_Version);
        vnp_Params.put("vnp_Command", vnp_Command);
        vnp_Params.put("vnp_TmnCode", vnp_TmnCode);
        vnp_Params.put("vnp_Amount", String.valueOf(amountInVNPayFormat));
        vnp_Params.put("vnp_CurrCode", "VND");
        vnp_Params.put("vnp_TxnRef", vnp_TxnRef);
        vnp_Params.put("vnp_OrderInfo", "Thanh toan don hang " + shipmentId);
        vnp_Params.put("vnp_OrderType", orderType);
        vnp_Params.put("vnp_Locale", "vn");
        vnp_Params.put("vnp_ReturnUrl", vnp_ReturnUrl);
        vnp_Params.put("vnp_IpAddr", "127.0.0.1");

        Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        vnp_Params.put("vnp_CreateDate", formatter.format(cld.getTime()));

        // Build URL
        List<String> fieldNames = new ArrayList<>(vnp_Params.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();

        for (String fieldName : fieldNames) {
            String fieldValue = vnp_Params.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                hashData.append(fieldName).append('=').append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                query.append(URLEncoder.encode(fieldName, StandardCharsets.US_ASCII.toString())).append('=').append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                query.append('&');
                hashData.append('&');
            }
        }

        query.setLength(query.length() - 1);
        hashData.setLength(hashData.length() - 1);

        String queryUrl = query.toString();
        String vnp_SecureHash = hmacSHA512(secretKey, hashData.toString());
        queryUrl += "&vnp_SecureHash=" + vnp_SecureHash;
        String paymentUrl = vnp_PayUrl + "?" + queryUrl;

        return ResponseEntity.ok(paymentUrl); // Trả link về cho Flutter mở lên
    }

    // =========================================================================
    // 2. API VNPAY GỌI TRẢ VỀ SAU KHI KHÁCH THANH TOÁN XONG
    // =========================================================================
    @GetMapping("/vnpay-return")
    public ResponseEntity<String> vnpayReturn(@RequestParam Map<String, String> params) {
        String status = params.get("vnp_ResponseCode");
        String txnRef = params.get("vnp_TxnRef"); // Định dạng: shipmentId_timestamp
        String transactionNo = params.get("vnp_TransactionNo");

        if ("00".equals(status)) { // "00" là mã thành công của VNPay
            Long shipmentId = Long.parseLong(txnRef.split("_")[0]);

            Shipment shipment = shipmentRepository.findById(shipmentId).orElse(null);
            if (shipment != null && shipment.getStatus() == ShipmentStatus.WAITING_PAYMENT) {

                // 🎯 1. CẬP NHẬT TRẠNG THÁI VÀ LƯU LỊCH SỬ
                shipment.setStatus(ShipmentStatus.PENDING); // Chuyển sang chờ tài xế
                shipment.setPaidAt(LocalDateTime.now());
                shipment.setTransactionNo(transactionNo);
                shipmentRepository.save(shipment);

                // 🎯 2. BẮN TÍN HIỆU TÌM TÀI XẾ (GỌI NOTIFICATION SERVICE QUA REST TEMPLATE)
                try {
                    RestTemplate restTemplate = new RestTemplate();
                    // Lưu ý: Đổi port 8080 thành cổng API Gateway hoặc Notification Service của Xuân nếu khác
                    String notifUrl = "http://localhost:8080/api/notifications/send";

                    Map<String, String> payload = new HashMap<>();
                    payload.put("topic", "ALL_DRIVERS"); // Bắn cho nhóm tài xế
                    payload.put("title", "🚀 CÓ ĐƠN HÀNG MỚI!");
                    payload.put("body", "Khách hàng vừa lên đơn SH-" + shipment.getId() + " và đã thanh toán. Nhận đơn ngay!");

                    // Gọi API phát sóng
                    restTemplate.postForEntity(notifUrl, payload, String.class);
                    System.out.println("🔥 ĐÃ BẮN THÔNG BÁO CHO TÀI XẾ THÀNH CÔNG ĐƠN SH-" + shipment.getId());
                } catch (Exception e) {
                    System.out.println("⚠️ Thanh toán OK nhưng lỗi gửi thông báo: " + e.getMessage());
                }

                return ResponseEntity.ok("Thanh toán thành công! Đã lên đơn tìm tài xế.");
            }
        }
        return ResponseEntity.badRequest().body("Thanh toán thất bại hoặc đơn hàng không hợp lệ!");
    }

    // Hàm mã hóa chữ ký (Bảo mật của VNPay)
    private String hmacSHA512(String key, String data) throws Exception {
        Mac hmac512 = Mac.getInstance("HmacSHA512");
        SecretKeySpec secretKey = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA512");
        hmac512.init(secretKey);
        byte[] result = hmac512.doFinal(data.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder(2 * result.length);
        for (byte b : result) {
            sb.append(String.format("%02x", b & 0xff));
        }
        return sb.toString();
    }
}