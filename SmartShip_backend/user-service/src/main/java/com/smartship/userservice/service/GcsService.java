package com.smartship.userservice.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
public class GcsService {

    @Value("${gcp.bucket-name}")
    private String bucketName;

    public String uploadFile(MultipartFile file) throws IOException {
        // 1. Đọc file JSON chứa key xác thực từ thư mục resources
        GoogleCredentials credentials = GoogleCredentials.fromStream(
                new ClassPathResource("gcp-credential.json").getInputStream()
        );

        Storage storage = StorageOptions.newBuilder().setCredentials(credentials).build().getService();

        // 2. Tạo tên file ngẫu nhiên để không bị trùng lặp trên Cloud (vd: 123e4567-e89b-12d3-a456-426614174000.jpg)
        String fileName = UUID.randomUUID().toString() + "-" + file.getOriginalFilename();

        // 3. Chuẩn bị thông tin file để đẩy lên GCS
        BlobId blobId = BlobId.of(bucketName, fileName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId).setContentType(file.getContentType()).build();

        // 4. Thực hiện đẩy file lên Cloud
        storage.create(blobInfo, file.getBytes());

        // 5. Trả về đường dẫn Public URL của file ảnh
        return String.format("https://storage.googleapis.com/%s/%s", bucketName, fileName);
    }
}