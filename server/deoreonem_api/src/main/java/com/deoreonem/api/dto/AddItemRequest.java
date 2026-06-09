package com.deoreonem.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class AddItemRequest {

    @NotBlank(message = "content must not be blank")
    @Size(max = 500, message = "content must not exceed 500 characters")
    private String content;

    public AddItemRequest() {}

    public AddItemRequest(String content) {
        this.content = content;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
