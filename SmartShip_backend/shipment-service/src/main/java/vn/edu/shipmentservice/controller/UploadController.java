package vn.edu.shipmentservice.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.edu.shipmentservice.service.GcsStorageService;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/shipments")
public class UploadController {

    @Autowired
    private GcsStorageService gcsStorageService;

    // 🎯 ĐÂY CHÍNH LÀ CÁI "TRẠM NHẬN ẢNH" MÀ FLUTTER ĐANG TÌM KIẾM
    @PostMapping("/upload-image")
    public ResponseEntity<Map<String, String>> uploadSingleImage(@RequestParam("file") MultipartFile file) {
        try {
            // Nhờ Google Cloud Storage lưu ảnh và trả về link
            String imageUrl = gcsStorageService.uploadPackageImage(file);

            // Đóng gói link ảnh vào JSON để gửi về cho Flutter
            Map<String, String> response = new HashMap<>();
            response.put("url", imageUrl);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}