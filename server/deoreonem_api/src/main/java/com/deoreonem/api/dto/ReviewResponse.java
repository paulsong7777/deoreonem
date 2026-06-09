package com.deoreonem.api.dto;

import java.util.List;
import java.util.UUID;

public class ReviewResponse {

    private UUID sessionId;
    private List<ItemResponse> items;

    public ReviewResponse() {}

    public ReviewResponse(UUID sessionId, List<ItemResponse> items) {
        this.sessionId = sessionId;
        this.items = items;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public List<ItemResponse> getItems() { return items; }
    public void setItems(List<ItemResponse> items) { this.items = items; }
}
