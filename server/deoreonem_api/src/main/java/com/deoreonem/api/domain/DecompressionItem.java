package com.deoreonem.api.domain;

import java.time.OffsetDateTime;
import java.util.UUID;

public class DecompressionItem {

    private UUID itemId;
    private UUID sessionId;
    private String content;
    private String category;
    private int sortOrder;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    // Default constructor (required by MyBatis)
    public DecompressionItem() {}

    // Getters and setters for all fields
    public UUID getItemId() { return itemId; }
    public void setItemId(UUID itemId) { this.itemId = itemId; }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
