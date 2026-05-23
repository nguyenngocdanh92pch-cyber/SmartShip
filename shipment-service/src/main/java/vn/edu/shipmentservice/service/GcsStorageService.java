package vn.edu.shipmentservice.service;

import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

public interface GcsStorageService {
    String uploadPackageImage(MultipartFile file) throws IOException;
}
