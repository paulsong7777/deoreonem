package com.deoreonem.api.dto;

import java.util.UUID;

public class FirstActionResponse {

    private UUID sessionId;
    private UUID firstActionItemId;

    public FirstActionResponse() {}

    public FirstActionResponse(UUID sessionId, UUID firstActionItemId) {
        this.sessionId = sessionId;
        this.firstActionItemId = firstActionItemId;
    }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public UUID getFirstActionItemId() { return firstActionItemId; }
    public void setFirstActionItemId(UUID firstActionItemId) { this.firstActionItemId = firstActionItemId; }
}
