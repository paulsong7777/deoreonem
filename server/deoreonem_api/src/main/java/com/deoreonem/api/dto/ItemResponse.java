package com.deoreonem.api.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public class ItemResponse {

    private UUID itemId;
    private UUID sessionId;
    private String content;
    private String category;
    private boolean isFirstAction;
    private int sortOrder;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public ItemResponse() {}

    public ItemResponse(UUID itemId, UUID sessionId, String content, String category,
                        boolean isFirstAction, int sortOrder,
                        OffsetDateTime createdAt, OffsetDateTime updatedAt) {
        this.itemId = itemId;
        this.sessionId = sessionId;
        this.content = content;
        this.category = category;
        this.isFirstAction = isFirstAction;
        this.sortOrder = sortOrder;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getItemId() { return itemId; }
    public void setItemId(UUID itemId) { this.itemId = itemId; }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public boolean getIsFirstAction() { return isFirstAction; }
    public void setIsFirstAction(boolean isFirstAction) { this.isFirstAction = isFirstAction; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
