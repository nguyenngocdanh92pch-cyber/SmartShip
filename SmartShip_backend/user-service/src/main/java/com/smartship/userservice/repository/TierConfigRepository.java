package com.smartship.userservice.repository;

import com.smartship.userservice.entity.TierConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TierConfigRepository extends JpaRepository<TierConfig, Long> {
}