package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class SessionAlreadyCompleteException extends ApiException {

    public SessionAlreadyCompleteException(String message) {
        super(ErrorCode.SESSION_ALREADY_COMPLETE, HttpStatus.CONFLICT, message);
    }
}
