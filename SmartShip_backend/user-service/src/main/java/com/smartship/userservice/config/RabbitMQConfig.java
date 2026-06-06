package com.smartship.userservice.config;

import org.springframework.amqp.core.Queue;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter; // Nhớ import cái này
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String PROFILE_QUEUE = "user.profile.create.queue";
    public static final String PROFILE_UPDATE_QUEUE = "user.profile.update.queue";

    @Bean
    public Queue profileQueue() {
        return new Queue(PROFILE_QUEUE, true);
    }

    @Bean
    public Queue profileUpdateQueue() {
        return new Queue(PROFILE_UPDATE_QUEUE, true);
    }

    // 🎯 ĐỔI SANG DÙNG JSON CONVERTER
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}