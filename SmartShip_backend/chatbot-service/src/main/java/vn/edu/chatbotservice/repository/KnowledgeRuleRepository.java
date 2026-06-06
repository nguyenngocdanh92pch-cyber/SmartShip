package vn.edu.chatbotservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.chatbotservice.entity.KnowledgeRule;

@Repository
public interface KnowledgeRuleRepository extends JpaRepository<KnowledgeRule, Long> {
}