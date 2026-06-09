package com.deoreonem.api.exception;

public final class ErrorCode {
    public static final String VALIDATION_ERROR = "VALIDATION_ERROR";
    public static final String SESSION_NOT_FOUND = "SESSION_NOT_FOUND";
    public static final String ITEM_NOT_FOUND = "ITEM_NOT_FOUND";
    public static final String SESSION_ALREADY_COMPLETE = "SESSION_ALREADY_COMPLETE";
    public static final String ITEM_NOT_IN_SESSION = "ITEM_NOT_IN_SESSION";
    public static final String INVALID_CATEGORY = "INVALID_CATEGORY";
    public static final String FIRST_ACTION_INELIGIBLE = "FIRST_ACTION_INELIGIBLE";
    public static final String INTERNAL_ERROR = "INTERNAL_ERROR";

    private ErrorCode() {}
}
