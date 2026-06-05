package com.smartship.userservice.config;

import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String PROFILE_QUEUE = "user.profile.create.queue";
    // Thêm hàng đợi mới cho việc update
    public static final String PROFILE_UPDATE_QUEUE = "user.profile.update.queue";

    @Bean
    public Queue profileQueue() {
        return new Queue(PROFILE_QUEUE, true);
    }

    // Khởi tạo Queue update trên RabbitMQ
    @Bean
    public Queue profileUpdateQueue() {
        return new Queue(PROFILE_UPDATE_QUEUE, true);
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}