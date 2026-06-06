package com.smartship.location_service.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Configuration
@RequiredArgsConstructor
public class RedisSubscriber {

    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Lắng nghe trực tiếp tin nhắn từ kênh Redis
    @Bean
    public RedisMessageListenerContainer container(RedisConnectionFactory connectionFactory) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);

        container.addMessageListener(new MessageListener() {
            @Override
            public void onMessage(Message message, byte[] pattern) {
                try {
                    String jsonPayload = new String(message.getBody());
                    JsonNode node = objectMapper.readTree(jsonPayload);
                    String driverId = node.get("driverId").asText();

                    // Gửi tin nhắn qua WebSocket tới kênh riêng của từng tài xế
                    // App Khách hàng sẽ lắng nghe ở kênh: /topic/driver/{driverId}
                    messagingTemplate.convertAndSend("/topic/driver/" + driverId, jsonPayload);

                } catch (Exception e) {
                    System.err.println("Lỗi khi forward Redis -> WebSocket: " + e.getMessage());
                }
            }
        }, new PatternTopic("driver-location-channel"));

        return container;
    }
}