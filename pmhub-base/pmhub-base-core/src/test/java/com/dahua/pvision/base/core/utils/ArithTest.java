package com.dahua.pvision.base.core.utils;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class ArithTest {

    // ---- add ----

    @Test
    void addTwoDecimals() {
        assertEquals(0.3, Arith.add(0.1, 0.2), 1e-10);
    }

    @Test
    void addNegativeValues() {
        assertEquals(-0.1, Arith.add(0.1, -0.2), 1e-10);
    }

    // ---- sub ----

    @Test
    void subBasic() {
        assertEquals(0.1, Arith.sub(0.3, 0.2), 1e-10);
    }

    @Test
    void subResultNegative() {
        assertEquals(-1.0, Arith.sub(1.0, 2.0), 1e-10);
    }

    // ---- mul ----

    @Test
    void mulDecimals() {
        assertEquals(0.06, Arith.mul(0.2, 0.3), 1e-10);
    }

    @Test
    void mulByZero() {
        assertEquals(0.0, Arith.mul(999.9, 0.0), 1e-10);
    }

    // ---- div ----

    @Test
    void divBasic() {
        assertEquals(2.0, Arith.div(6.0, 3.0), 1e-10);
    }

    @Test
    void divNonTerminating() {
        // 1/3 精确到10位
        assertEquals(0.3333333333, Arith.div(1.0, 3.0), 1e-10);
    }

    @Test
    void divZeroDividendReturnsZero() {
        assertEquals(0.0, Arith.div(0.0, 5.0), 1e-10);
    }

    @Test
    void divNegativeScale() {
        assertThrows(IllegalArgumentException.class, () -> Arith.div(1.0, 2.0, -1));
    }

    // ---- round ----

    @Test
    void roundHalfUp() {
        assertEquals(1.24, Arith.round(1.235, 2), 1e-10);
    }

    @Test
    void roundToInteger() {
        assertEquals(3.0, Arith.round(3.4999, 0), 1e-10);
    }

    @Test
    void roundNegativeScaleThrows() {
        assertThrows(IllegalArgumentException.class, () -> Arith.round(1.0, -1));
    }
}
