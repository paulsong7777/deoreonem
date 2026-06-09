package com.deoreonem.api.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public class SessionResponse {

    private UUID sessionId;
    private String status;
    private UUID firstActionItemId;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public SessionResponse() {}

    public SessionResponse(UUID sessionId, String status, UUID firstActionItemId,
                           OffsetDateTime createdAt, OffsetDateTime updatedAt) {
        this.sessionId = sessionId;
        this.status = status;
        this.firstActionItemId = firstActionItemId;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public UUID getFirstActionItemId() { return firstActionItemId; }
    public void setFirstActionItemId(UUID firstActionItemId) { this.firstActionItemId = firstActionItemId; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
