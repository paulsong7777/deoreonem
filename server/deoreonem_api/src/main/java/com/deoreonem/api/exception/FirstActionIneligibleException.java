package com.deoreonem.api.exception;

import org.springframework.http.HttpStatus;

public class FirstActionIneligibleException extends ApiException {

    public FirstActionIneligibleException(String message) {
        super(ErrorCode.FIRST_ACTION_INELIGIBLE, HttpStatus.BAD_REQUEST, message);
    }
}
