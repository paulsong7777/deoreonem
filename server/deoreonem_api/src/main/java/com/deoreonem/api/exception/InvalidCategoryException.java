package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class InvalidCategoryException extends ApiException {

    public InvalidCategoryException(String message) {
        super(ErrorCode.INVALID_CATEGORY, HttpStatus.BAD_REQUEST, message);
    }
}
