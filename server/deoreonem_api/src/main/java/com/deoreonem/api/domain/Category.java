package com.deoreonem.api.domain;

public enum Category {
    NOW, TOMORROW, THIS_WEEK, WAITING, MEMO, WORRY_ONLY, DROP;

    public static boolean isValid(String value) {
        if (value == null) return false;
        try {
            Category.valueOf(value);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    public static boolean isFirstActionEligible(String category) {
        return NOW.name().equals(category)
                || TOMORROW.name().equals(category)
                || THIS_WEEK.name().equals(category);
    }
}
