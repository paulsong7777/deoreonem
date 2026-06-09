package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class ItemNotInSessionException extends ApiException {

    public ItemNotInSessionException(String message) {
        super(ErrorCode.ITEM_NOT_IN_SESSION, HttpStatus.BAD_REQUEST, message);
    }
}
