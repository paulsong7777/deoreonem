package com.deoreonem.api.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public class SetFirstActionRequest {

    @NotNull(message = "itemId must not be null")
    private UUID itemId;

    public SetFirstActionRequest() {}

    public SetFirstActionRequest(UUID itemId) {
        this.itemId = itemId;
    }

    public UUID getItemId() {
        return itemId;
    }

    public void setItemId(UUID itemId) {
        this.itemId = itemId;
    }
}
