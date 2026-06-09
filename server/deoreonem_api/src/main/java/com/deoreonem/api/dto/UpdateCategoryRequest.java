package com.deoreonem.api.dto;

import jakarta.validation.constraints.NotNull;

public class UpdateCategoryRequest {

    @NotNull(message = "category must not be null")
    private String category;

    public UpdateCategoryRequest() {}

    public UpdateCategoryRequest(String category) {
        this.category = category;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }
}
