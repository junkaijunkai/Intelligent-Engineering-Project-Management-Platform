package com.laigeoffer.pmhub.base.core.utils;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class ListPagingUtilTest {

    private static final List<Integer> TEN = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    // ---- 首页 ----

    @Test
    void firstPageReturnsCorrectSlice() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(1, 3, TEN);
        assertEquals(Arrays.asList(1, 2, 3), result.getList());
    }

    @Test
    void firstPageMetadata() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(1, 3, TEN);
        assertEquals(1, result.getPageNum());
        assertEquals(3, result.getPageSize());
        assertEquals(10, result.getTotal());
        assertEquals(4, result.getPages()); // ceil(10/3) = 4
        assertEquals(0, result.getStar());
    }

    // ---- 中间页 ----

    @Test
    void middlePageReturnsCorrectSlice() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(2, 3, TEN);
        assertEquals(Arrays.asList(4, 5, 6), result.getList());
    }

    // ---- 末页（不足一页）----

    @Test
    void lastPageReturnsRemainder() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(4, 3, TEN);
        assertEquals(Collections.singletonList(10), result.getList());
    }

    // ---- 整除时的总页数 ----

    @Test
    void exactDivisionPageCount() {
        List<Integer> nine = TEN.subList(0, 9);
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(1, 3, nine);
        assertEquals(3, result.getPages());
    }

    // ---- null 参数默认值 ----

    @Test
    void nullPageNumDefaultsToOne() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(null, 5, TEN);
        assertEquals(1, result.getPageNum());
        assertEquals(Arrays.asList(1, 2, 3, 4, 5), result.getList());
    }

    @Test
    void nullPageSizeDefaultsToTen() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(1, null, TEN);
        assertEquals(10, result.getPageSize());
        assertEquals(TEN, result.getList());
    }

    // ---- 空列表 ----

    @Test
    void emptyListReturnsEmptySlice() {
        ListPagingUtil result = ListPagingUtil.getListPagingUtil(1, 10, Collections.emptyList());
        assertEquals(0, result.getTotal());
        assertEquals(0, result.getPages());
        assertTrue(result.getList().isEmpty());
    }
}
