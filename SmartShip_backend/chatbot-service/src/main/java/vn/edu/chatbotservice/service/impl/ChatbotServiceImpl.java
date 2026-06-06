package vn.edu.chatbotservice.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.SystemPromptTemplate;
import org.springframework.ai.document.Document;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import vn.edu.chatbotservice.dto.ChatMessageDto;
import vn.edu.chatbotservice.entity.KnowledgeRule;
import vn.edu.chatbotservice.repository.KnowledgeRuleRepository;
import vn.edu.chatbotservice.service.ChatbotService;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ChatbotServiceImpl implements ChatbotService {

    private final ChatClient chatClient;
    private final VectorStore vectorStore;
    private final KnowledgeRuleRepository ruleRepository;
    private final JdbcTemplate jdbcTemplate;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    public ChatbotServiceImpl(ChatClient.Builder chatClientBuilder,
                              VectorStore vectorStore,
                              KnowledgeRuleRepository ruleRepository,
                              JdbcTemplate jdbcTemplate,
                              StringRedisTemplate redisTemplate,
                              ObjectMapper objectMapper) {
        this.chatClient = chatClientBuilder.build();
        this.vectorStore = vectorStore;
        this.ruleRepository = ruleRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    private void saveMessageToRedis(Long userId, String role, String content) {
        String key = "chat:history:" + userId;
        try {
            ChatMessageDto message = new ChatMessageDto(role, content);
            String jsonMessage = objectMapper.writeValueAsString(message);
            redisTemplate.opsForList().rightPush(key, jsonMessage);
            redisTemplate.expire(key, Duration.ofDays(7));
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }

    @Override
    public String askQuestion(Long userId, String userMessage) {
        saveMessageToRedis(userId, "USER", userMessage);

        List<Document> similarDocuments = vectorStore.similaritySearch(
                SearchRequest.builder().query(userMessage).topK(3).build()
        );

        String context = similarDocuments.stream()
                .map(Document::getText)
                .collect(Collectors.joining("\n\n"));

        String systemMessageText = """
            Bạn là nhân viên hỗ trợ khách hàng của ứng dụng giao hàng SmartShip.
            Nhiệm vụ của bạn là trả lời câu hỏi dựa trên THÔNG TIN NGỮ CẢNH bên dưới.
            Nếu thông tin ngữ cảnh không có câu trả lời, hãy nói: "Dạ, hiện tại em chưa có thông tin về vấn đề này. Mong quý khách liên hệ tổng đài 1900-xxxx ạ."
            Tuyệt đối không được tự bịa ra thông tin hoặc lấy kiến thức ngoài Internet.
            Trả lời bằng tiếng Việt, ngắn gọn, lịch sự và thân thiện.
            
            THÔNG TIN NGỮ CẢNH:
            {context}
            """;

        SystemPromptTemplate systemPromptTemplate = new SystemPromptTemplate(systemMessageText);
        var systemMessage = systemPromptTemplate.createMessage(Map.of("context", context));

        String botReply = chatClient.prompt()
                .system(systemMessage.getText())
                .user(userMessage)
                .call()
                .content();

        saveMessageToRedis(userId, "BOT", botReply);

        return botReply;
    }

    @Override
    public List<ChatMessageDto> getChatHistory(Long userId) {
        String key = "chat:history:" + userId;
        List<ChatMessageDto> history = new ArrayList<>();
        List<String> jsonMessages = redisTemplate.opsForList().range(key, 0, -1);

        if (jsonMessages != null) {
            for (String json : jsonMessages) {
                try {
                    history.add(objectMapper.readValue(json, ChatMessageDto.class));
                } catch (JsonProcessingException e) {
                    e.printStackTrace();
                }
            }
        }
        return history;
    }

    @Override
    public KnowledgeRule addRule(KnowledgeRule rule) {
        KnowledgeRule savedRule = ruleRepository.save(rule);
        Document parentDoc = new Document(savedRule.getContent(), Map.of(
                "title", savedRule.getTitle(),
                "rule_id", String.valueOf(savedRule.getId())
        ));
        TokenTextSplitter splitter = new TokenTextSplitter(500, 100, 5, 10000, true);
        vectorStore.add(splitter.apply(List.of(parentDoc)));
        return savedRule;
    }

    @Override
    public KnowledgeRule updateRule(Long id, KnowledgeRule updatedRule) {
        KnowledgeRule existing = ruleRepository.findById(id).orElseThrow();
        existing.setTitle(updatedRule.getTitle());
        existing.setContent(updatedRule.getContent());
        KnowledgeRule savedRule = ruleRepository.save(existing);

        String sql = "DELETE FROM vector_store WHERE metadata->>'rule_id' = ?";
        jdbcTemplate.update(sql, String.valueOf(id));

        Document parentDoc = new Document(savedRule.getContent(), Map.of(
                "title", savedRule.getTitle(),
                "rule_id", String.valueOf(id)
        ));
        TokenTextSplitter splitter = new TokenTextSplitter(500, 100, 5, 10000, true);
        vectorStore.add(splitter.apply(List.of(parentDoc)));

        return savedRule;
    }

    @Override
    public void deleteRule(Long id) {
        ruleRepository.deleteById(id);
        String sql = "DELETE FROM vector_store WHERE metadata->>'rule_id' = ?";
        jdbcTemplate.update(sql, String.valueOf(id));
    }

    @Override
    public List<KnowledgeRule> getAllRules() {
        return ruleRepository.findAll();
    }
}