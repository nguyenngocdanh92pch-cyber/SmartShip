package com.example.notification_service.repository; // 🚀 Sửa lại cho đúng package

import com.example.notification_service.entity.CampaignHistory; // Import đúng entity bạn vừa sửa
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CampaignHistoryRepository extends JpaRepository<CampaignHistory, Long> {
    List<CampaignHistory> findAllByOrderByCreatedAtDesc();
}