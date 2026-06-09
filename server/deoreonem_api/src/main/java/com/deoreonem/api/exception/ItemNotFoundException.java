package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class ItemNotFoundException extends ApiException {

    public ItemNotFoundException(String message) {
        super(ErrorCode.ITEM_NOT_FOUND, HttpStatus.NOT_FOUND, message);
    }
}
