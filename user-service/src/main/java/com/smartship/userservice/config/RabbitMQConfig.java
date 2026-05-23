package com.smartship.userservice.config;

import org.springframework.amqp.core.Queue;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String PROFILE_QUEUE = "user.profile.create.queue";

    // Khởi tạo Queue trên RabbitMQ nếu chưa có
    @Bean
    public Queue profileQueue() {
        return new Queue(PROFILE_QUEUE, true); // true = durable (lưu lại khi restart RabbitMQ)
    }
}