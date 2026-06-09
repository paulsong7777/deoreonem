package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class SessionNotFoundException extends ApiException {

    public SessionNotFoundException(String message) {
        super(ErrorCode.SESSION_NOT_FOUND, HttpStatus.NOT_FOUND, message);
    }
}
