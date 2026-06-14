package com.dahua.pvision.base.core.core.text;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class StrFormatterTest {

    // ---- 正常占位符 ----

    @Test
    void singlePlaceholder() {
        assertEquals("hello world", StrFormatter.format("hello {}", "world"));
    }

    @Test
    void multiplePlaceholders() {
        assertEquals("a-b-c", StrFormatter.format("{}-{}-{}", "a", "b", "c"));
    }

    @Test
    void fewerArgsThanPlaceholders() {
        // 多余占位符原样保留
        assertEquals("a-{}", StrFormatter.format("{}-{}", "a"));
    }

    @Test
    void moreArgsThanPlaceholders() {
        // 多余参数直接忽略
        assertEquals("a", StrFormatter.format("{}", "a", "b"));
    }

    @Test
    void nonStringArgument() {
        assertEquals("value=42", StrFormatter.format("value={}", 42));
    }

    // ---- 空 / null 边界 ----

    @Test
    void nullPatternReturnsNull() {
        assertNull(StrFormatter.format(null, "x"));
    }

    @Test
    void emptyPatternReturnsEmpty() {
        assertEquals("", StrFormatter.format("", "x"));
    }

    @Test
    void nullArgsReturnsPattern() {
        assertEquals("hello {}", StrFormatter.format("hello {}", (Object[]) null));
    }

    @Test
    void emptyArgsReturnsPattern() {
        assertEquals("hello {}", StrFormatter.format("hello {}"));
    }

    @Test
    void patternWithNoPlaceholder() {
        assertEquals("hello", StrFormatter.format("hello", "x"));
    }

    // ---- 转义 ----

    @Test
    void escapedPlaceholderIsLiteral() {
        // \{} 输出字面量 {}，消耗参数跳过
        assertEquals("this is {} for a", StrFormatter.format("this is \\{} for {}", "a", "b"));
    }

    @Test
    void doubleEscapeBeforePlaceholder() {
        // \\{} 输出 \a（转义符本身被转义，占位符仍有效）
        assertEquals("this is \\a for b", StrFormatter.format("this is \\\\{} for {}", "a", "b"));
    }
}
