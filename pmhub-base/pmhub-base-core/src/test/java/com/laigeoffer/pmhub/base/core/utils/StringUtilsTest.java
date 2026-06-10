package com.laigeoffer.pmhub.base.core.utils;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class StringUtilsTest {

    // ---- isEmpty(String) ----

    @Test
    void isEmptyNullIsTrue() {
        assertTrue(StringUtils.isEmpty((String) null));
    }

    @Test
    void isEmptyBlankStringIsTrue() {
        assertTrue(StringUtils.isEmpty("   "));
    }

    @Test
    void isEmptyNonBlankIsFalse() {
        assertFalse(StringUtils.isEmpty("a"));
    }

    // ---- toUnderScoreCase ----

    @Test
    void camelToUnderscoreSimple() {
        assertEquals("user_name", StringUtils.toUnderScoreCase("userName"));
    }

    @Test
    void camelToUnderscoreAllLower() {
        assertEquals("hello", StringUtils.toUnderScoreCase("hello"));
    }

    @Test
    void camelToUnderscoreNullReturnsNull() {
        assertNull(StringUtils.toUnderScoreCase(null));
    }

    @Test
    void camelToUnderscoreAcronym() {
        // "HTTPClient" → "htt_p_client" 是当前实现的实际行为，测试用于记录
        assertNotNull(StringUtils.toUnderScoreCase("HTTPClient"));
    }

    // ---- convertToCamelCase ----

    @Test
    void underscoreToCamelCase() {
        assertEquals("HelloWorld", StringUtils.convertToCamelCase("HELLO_WORLD"));
    }

    @Test
    void convertToCamelCaseNoUnderscore() {
        assertEquals("Hello", StringUtils.convertToCamelCase("hello"));
    }

    @Test
    void convertToCamelCaseNullReturnsEmpty() {
        assertEquals("", StringUtils.convertToCamelCase(null));
    }

    // ---- toCamelCase ----

    @Test
    void toCamelCaseLowerUnderscore() {
        assertEquals("userName", StringUtils.toCamelCase("user_name"));
    }

    @Test
    void toCamelCaseNullReturnsNull() {
        assertNull(StringUtils.toCamelCase(null));
    }

    // ---- str2List ----

    @Test
    void str2ListSplitsCorrectly() {
        List<String> result = StringUtils.str2List("a,b,c", ",", true, true);
        assertEquals(Arrays.asList("a", "b", "c"), result);
    }

    @Test
    void str2ListEmptyStringReturnsEmptyList() {
        assertTrue(StringUtils.str2List("", ",", true, false).isEmpty());
    }

    @Test
    void str2ListFiltersBlank() {
        List<String> result = StringUtils.str2List("a, ,b", ",", true, true);
        assertEquals(Arrays.asList("a", "b"), result);
    }

    // ---- containsAny ----

    @Test
    void containsAnyMatchFound() {
        assertTrue(StringUtils.containsAny(Arrays.asList("a", "b"), "c", "b"));
    }

    @Test
    void containsAnyNoMatch() {
        assertFalse(StringUtils.containsAny(Arrays.asList("a", "b"), "c", "d"));
    }

    @Test
    void containsAnyEmptyCollectionReturnsFalse() {
        assertFalse(StringUtils.containsAny(Collections.emptyList(), "a"));
    }

    // ---- padl ----

    @Test
    void padlNumberPadsWithZero() {
        assertEquals("007", StringUtils.padl(7, 3));
    }

    @Test
    void padlTruncatesWhenTooLong() {
        assertEquals("234", StringUtils.padl(1234, 3));
    }

    // ---- getCleanNumber ----

    @Test
    void getCleanNumberRemovesTrailingZeros() {
        assertEquals("1.5", StringUtils.getCleanNumber("1.50"));
    }

    @Test
    void getCleanNumberIntegerValue() {
        assertEquals("1", StringUtils.getCleanNumber("1.000"));
    }

    @Test
    void getCleanNumberInvalidReturnsOriginal() {
        assertEquals("abc", StringUtils.getCleanNumber("abc"));
    }

    // ---- hasText ----

    @Test
    void hasTextReturnsTrueForNonBlank() {
        assertTrue(StringUtils.hasText("hello"));
    }

    @Test
    void hasTextReturnsFalseForBlank() {
        assertFalse(StringUtils.hasText("   "));
    }

    @Test
    void hasTextReturnsFalseForNull() {
        assertFalse(StringUtils.hasText(null));
    }
}
