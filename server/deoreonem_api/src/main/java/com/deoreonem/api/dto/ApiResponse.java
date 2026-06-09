package com.deoreonem.api.dto;

public class ApiResponse<T> {

    private final boolean success = true;
    private final T data;

    public ApiResponse(T data) {
        this.data = data;
    }

    public boolean isSuccess() {
        return success;
    }

    public T getData() {
        return data;
    }
}
