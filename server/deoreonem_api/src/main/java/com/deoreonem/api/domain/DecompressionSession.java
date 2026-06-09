package com.deoreonem.api.domain;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public class DecompressionSession {

    private UUID sessionId;
    private String status;
    private UUID firstActionItemId;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private List<DecompressionItem> items;

    // Default constructor (required by MyBatis)
    public DecompressionSession() {}

    // Getters and setters for all fields
    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public UUID getFirstActionItemId() { return firstActionItemId; }
    public void setFirstActionItemId(UUID firstActionItemId) { this.firstActionItemId = firstActionItemId; }

    public OffsetDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public List<DecompressionItem> getItems() { return items; }
    public void setItems(List<DecompressionItem> items) { this.items = items; }
}
