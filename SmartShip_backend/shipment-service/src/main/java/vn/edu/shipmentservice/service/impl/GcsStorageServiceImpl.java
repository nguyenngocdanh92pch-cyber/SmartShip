package vn.edu.shipmentservice.service.impl;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import vn.edu.shipmentservice.service.GcsStorageService;

import java.io.IOException;
import java.util.UUID;

@Service
public class GcsStorageServiceImpl implements GcsStorageService {

    private final String bucketName;
    private Storage storage; // Bỏ final để khởi tạo an toàn trong try-catch

    public GcsStorageServiceImpl(
            @Value("${google.cloud.storage.bucket-name:smartship-images-bucket}") String bucketName,
            @Value("${google.cloud.storage.project-id}") String projectId,
            @Value("${google.cloud.storage.credentials-path}") Resource credentialsResource) {

        this.bucketName = bucketName;

        // 🛡️ Giữ logic an toàn: Tránh sập app khi chạy local nếu thiếu file cấu hình JSON
        try {
            if (credentialsResource != null && credentialsResource.exists()) {
                // Đọc thông tin xác thực từ file JSON
                GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsResource.getInputStream());

                // Khởi tạo dịch vụ Google Cloud Storage
                this.storage = StorageOptions.newBuilder()
                        .setProjectId(projectId)
                        .setCredentials(credentials)
                        .build()
                        .getService();
            } else {
                System.err.println("⚠️ CẢNH BÁO: Không tìm thấy file credentials JSON trong thư mục resources!");
            }
        } catch (Exception e) {
            System.err.println("⚠️ Lỗi khởi tạo Google Cloud Storage: " + e.getMessage());
        }
    }

    @Override
    public String uploadPackageImage(MultipartFile file) throws IOException {
        // 🛡️ Chặn ngay nếu hệ thống chưa kết nối thành công tới GCS Bucket
        if (this.storage == null) {
            throw new IOException("Chưa thể kết nối Google Cloud Storage do thiếu hoặc sai cấu hình file JSON.");
        }

        // Xử lý tên file: Thay thế dấu cách bằng dấu gạch ngang để tránh lỗi URL trên Mobile/Flutter
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null) {
            originalFilename = originalFilename.replaceAll("\\s+", "-");
        } else {
            originalFilename = "image.png"; // Tên mặc định phòng trường hợp bị null
        }

        // Tạo tên file độc nhất bằng UUID để tránh bị ghi đè dữ liệu trên Cloud
        String fileName = UUID.randomUUID().toString() + "-" + originalFilename;

        // Cấu hình thông tin file đẩy lên GCS Bucket
        BlobId blobId = BlobId.of(bucketName, fileName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(file.getContentType())
                .build();

        // Thực hiện đẩy mảng bytes data của ảnh lên Cloud
        storage.create(blobInfo, file.getBytes());

        // Trả về URL public của ảnh phục vụ lưu trữ vào Database
        return String.format("https://storage.googleapis.com/%s/%s", bucketName, fileName);
    }
}