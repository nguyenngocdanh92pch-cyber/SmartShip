package vn.edu.chatbotservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.chatbotservice.dto.ChatMessageDto;
import vn.edu.chatbotservice.entity.KnowledgeRule;
import vn.edu.chatbotservice.service.ChatbotService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/chatbot")
public class ChatbotController {

    private final ChatbotService chatbotService;

    public ChatbotController(ChatbotService chatbotService) {
        this.chatbotService = chatbotService;
    }

    @PostMapping("/ask")
    public ResponseEntity<?> askChatbot(@RequestBody Map<String, Object> request) {
        Long userId = Long.valueOf(request.get("userId").toString());
        String message = request.get("message").toString();

        String reply = chatbotService.askQuestion(userId, message);
        return ResponseEntity.ok(Map.of("reply", reply));
    }

    @GetMapping("/history/{userId}")
    public ResponseEntity<List<ChatMessageDto>> getHistory(@PathVariable Long userId) {
        return ResponseEntity.ok(chatbotService.getChatHistory(userId));
    }

    @GetMapping("/knowledge")
    public ResponseEntity<List<KnowledgeRule>> getAllKnowledge() {
        return ResponseEntity.ok(chatbotService.getAllRules());
    }

    @PostMapping("/knowledge")
    public ResponseEntity<KnowledgeRule> addKnowledge(@RequestBody KnowledgeRule rule) {
        return ResponseEntity.ok(chatbotService.addRule(rule));
    }

    @PutMapping("/knowledge/{id}")
    public ResponseEntity<KnowledgeRule> updateKnowledge(@PathVariable Long id, @RequestBody KnowledgeRule rule) {
        return ResponseEntity.ok(chatbotService.updateRule(id, rule));
    }

    @DeleteMapping("/knowledge/{id}")
    public ResponseEntity<?> deleteKnowledge(@PathVariable Long id) {
        chatbotService.deleteRule(id);
        return ResponseEntity.ok(Map.of("message", "Đã xóa thành công!"));
    }
}