package com.deoreonem.api.dto;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public class SummaryResponse {

    private UUID sessionId;
    private String status;
    private int totalItems;
    private ItemResponse firstActionItem;
    private Map<String, List<ItemResponse>> itemsByCategory;

    public SummaryResponse() {}

    public SummaryResponse(UUID sessionId, String status, int totalItems,
                           ItemResponse firstActionItem,
                           Map<String, List<ItemResponse>> itemsByCategory) {
        this.sessionId = sessionId;
        this.status = status;
        this.totalItems = totalItems;
        this.firstActionItem = firstActionItem;
        this.itemsByCategory = itemsByCategory;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getTotalItems() { return totalItems; }
    public void setTotalItems(int totalItems) { this.totalItems = totalItems; }

    public ItemResponse getFirstActionItem() { return firstActionItem; }
    public void setFirstActionItem(ItemResponse firstActionItem) { this.firstActionItem = firstActionItem; }

    public Map<String, List<ItemResponse>> getItemsByCategory() { return itemsByCategory; }
    public void setItemsByCategory(Map<String, List<ItemResponse>> itemsByCategory) { this.itemsByCategory = itemsByCategory; }
}
