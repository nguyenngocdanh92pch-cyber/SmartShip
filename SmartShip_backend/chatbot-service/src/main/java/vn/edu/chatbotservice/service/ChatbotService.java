package vn.edu.chatbotservice.service;

import vn.edu.chatbotservice.dto.ChatMessageDto;
import vn.edu.chatbotservice.entity.KnowledgeRule;
import java.util.List;

public interface ChatbotService {
    // Hàm chat cũ
    String askQuestion(Long userId, String userMessage);
    List<ChatMessageDto> getChatHistory(Long userId);
    // Các hàm quản lý tri thức mới
    KnowledgeRule addRule(KnowledgeRule rule);
    KnowledgeRule updateRule(Long id, KnowledgeRule updatedRule);
    void deleteRule(Long id);
    List<KnowledgeRule> getAllRules();
}