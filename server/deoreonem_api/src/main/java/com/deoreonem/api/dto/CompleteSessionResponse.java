package com.deoreonem.api.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public class CompleteSessionResponse {

    private UUID sessionId;
    private String status;
    private OffsetDateTime completedAt;

    public CompleteSessionResponse() {}

    public CompleteSessionResponse(UUID sessionId, String status, OffsetDateTime completedAt) {
        this.sessionId = sessionId;
        this.status = status;
        this.completedAt = completedAt;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
}
