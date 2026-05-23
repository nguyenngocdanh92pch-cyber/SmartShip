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
    private final Storage storage;

    public GcsStorageServiceImpl(
            @Value("${google.cloud.storage.bucket-name}") String bucketName,
            @Value("${google.cloud.storage.project-id}") String projectId,
            @Value("${google.cloud.storage.credentials-path}") Resource credentialsResource) throws IOException {

        this.bucketName = bucketName;

        // Đọc thông tin xác thực từ file JSON
        GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsResource.getInputStream());

        // Khởi tạo Storage với credentials vừa đọc
        this.storage = StorageOptions.newBuilder()
                .setProjectId(projectId)
                .setCredentials(credentials)
                .build()
                .getService();
    }

    @Override
    public String uploadPackageImage(MultipartFile file) throws IOException {
        // Xử lý tên file: Thay thế dấu cách (nếu có) để URL không bị lỗi khi gọi trên Mobile
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null) {
            originalFilename = originalFilename.replaceAll("\\s+", "-");
        }

        String fileName = UUID.randomUUID().toString() + "-" + originalFilename;

        BlobId blobId = BlobId.of(bucketName, fileName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId).setContentType(file.getContentType()).build();

        // Upload lên GCS
        storage.create(blobInfo, file.getBytes());

        // Trả về URL public của ảnh
        return String.format("https://storage.googleapis.com/%s/%s", bucketName, fileName);
    }
}