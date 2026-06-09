package com.deoreonem.api.mapper;

import com.deoreonem.api.domain.DecompressionSession;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.OffsetDateTime;
import java.util.UUID;

@Mapper
public interface DecompressionSessionMapper {

    void insertSession(DecompressionSession session);

    DecompressionSession findById(UUID sessionId);

    void updateStatus(@Param("sessionId") UUID sessionId, @Param("status") String status);

    void updateFirstAction(@Param("sessionId") UUID sessionId, @Param("itemId") UUID itemId);

    void updateCompletedAt(@Param("sessionId") UUID sessionId, @Param("completedAt") OffsetDateTime completedAt);
}
