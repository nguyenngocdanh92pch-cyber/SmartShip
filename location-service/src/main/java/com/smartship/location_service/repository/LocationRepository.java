package com.smartship.location_service.repository;

import com.smartship.location_service.entity.LocationRecord;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LocationRepository extends MongoRepository<LocationRecord, String> {
}