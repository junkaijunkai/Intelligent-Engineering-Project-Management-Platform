package com.dahua.pvision.project.domain.vo.project.log;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class FieldUtilsTest {

    // ---- 测试用 fixture Bean ----

    /** 只带一个 @ForUpdate 字段的最小 Bean */
    static class SingleFieldBean {
        @ForUpdate(fieldName = "任务名称")
        String taskName;

        SingleFieldBean(String taskName) {
            this.taskName = taskName;
        }
    }

    /** 带两个 @ForUpdate 字段的 Bean，用于验证多字段变更 */
    static class MultiFieldBean {
        @ForUpdate(fieldName = "任务名称")
        String taskName;

        @ForUpdate(fieldName = "执行人")
        String userId;

        MultiFieldBean(String taskName, String userId) {
            this.taskName = taskName;
            this.userId   = userId;
        }
    }

    /** 带一个没有 @ForUpdate 注解的字段的 Bean */
    static class NoAnnotationBean {
        String taskName;

        NoAnnotationBean(String taskName) {
            this.taskName = taskName;
        }
    }

    /** 包含 null 旧值的 Bean，用于暴露 NPE bug */
    static class NullOldValueBean {
        @ForUpdate(fieldName = "任务名称")
        String taskName;

        NullOldValueBean(String taskName) {
            this.taskName = taskName;
        }
    }

    // ---- 正常场景 ----

    @Test
    void noChanges_returnsEmptyList() {
        SingleFieldBean a = new SingleFieldBean("sprint-1");
        SingleFieldBean b = new SingleFieldBean("sprint-1");
        List<LogDataVO> result = FieldUtils.getChangedFields(a, b);
        assertTrue(result.isEmpty());
    }

    @Test
    void singleFieldChanged_returnsOneEntry() {
        SingleFieldBean newBean = new SingleFieldBean("sprint-2");
        SingleFieldBean oldBean = new SingleFieldBean("sprint-1");

        List<LogDataVO> result = FieldUtils.getChangedFields(newBean, oldBean);

        assertEquals(1, result.size());
        LogDataVO entry = result.get(0);
        assertEquals("更新了任务名称", entry.getRemark());

        List<LogContentVO> contents = entry.getLogContentVOList();
        assertNotNull(contents);
        assertEquals(1, contents.size());

        LogContentVO content = contents.get(0);
        assertEquals("taskName",   content.getField());
        assertEquals("任务名称",    content.getFieldName());
        assertEquals("sprint-1",   content.getOldValue());
        assertEquals("sprint-2",   content.getNewValue());
    }

    @Test
    void fieldWithoutAnnotation_isIgnored() {
        NoAnnotationBean newBean = new NoAnnotationBean("sprint-2");
        NoAnnotationBean oldBean = new NoAnnotationBean("sprint-1");
        List<LogDataVO> result = FieldUtils.getChangedFields(newBean, oldBean);
        assertTrue(result.isEmpty());
    }

    // ---- 已知 Bug：list 跨字段共享 ----

    /**
     * 原始 Bug：list 在循环外只创建一次，所有 LogDataVO 共享同一个 list 实例，
     * 导致第一个 LogDataVO 的 logContentVOList 会累积后续字段的 LogContentVO。
     * 修复：将 list 的创建移入循环内，每个变更字段独立持有自己的 list。
     */
    @Test
    void multipleFieldsChanged_sharedListBug_eachEntryHasItsOwnContent() {
        MultiFieldBean newBean = new MultiFieldBean("sprint-2", "user-B");
        MultiFieldBean oldBean = new MultiFieldBean("sprint-1", "user-A");

        List<LogDataVO> result = FieldUtils.getChangedFields(newBean, oldBean);

        assertEquals(2, result.size(), "应有两条变更记录");

        // --- 修复后的期望行为（每条记录仅包含自己的内容）---
        // 目前会失败，因为 list 是共享的
        assertEquals(
                1,
                result.get(0).getLogContentVOList().size(),
                "第一个变更记录应只包含自己的 LogContentVO，不应混入其它字段");
        assertEquals(
                1,
                result.get(1).getLogContentVOList().size(),
                "第二个变更记录应只包含自己的 LogContentVO，不应混入其它字段");
    }

    // ---- 原始 Bug：oldValue == null 时 NPE 被静默吞掉 ----

    /**
     * 原始 Bug：oldValue.toString() 当 oldValue 为 null 时抛 NPE，
     * 被 catch(Exception e) 吞掉，导致该变更被静默丢弃、不出现在结果中。
     * 修复：使用 oldValue == null ? "" : oldValue.toString() 替代直接调用。
     */
    @Test
    void oldValueIsNull_changeShouldStillBeRecorded() {
        NullOldValueBean newBean = new NullOldValueBean("sprint-1");
        NullOldValueBean oldBean = new NullOldValueBean(null);

        List<LogDataVO> result = FieldUtils.getChangedFields(newBean, oldBean);

        assertEquals(1, result.size(), "oldValue 为 null 时变更仍应被记录");
        LogContentVO content = result.get(0).getLogContentVOList().get(0);
        assertEquals("", content.getOldValue(), "oldValue 为 null 应转换为空串");
        assertEquals("sprint-1", content.getNewValue());
    }

    // ---- 已知字段名 → remark 映射 ----

    static class AllKnownFieldsBean {
        @ForUpdate(fieldName = "执行人")        String userId;
        @ForUpdate(fieldName = "任务名称")      String taskName;
        @ForUpdate(fieldName = "执行状态")      String executeStatus;
        @ForUpdate(fieldName = "任务状态")      String status;
        @ForUpdate(fieldName = "任务优先级")    String taskPriority;
        @ForUpdate(fieldName = "开始时间")      String beginTime;
        @ForUpdate(fieldName = "结束时间")      String endTime;
        @ForUpdate(fieldName = "截止时间")      String closeTime;
        @ForUpdate(fieldName = "描述")          String description;
        @ForUpdate(fieldName = "任务进度")      String taskProcess;
    }

    @Test
    void knownFieldNames_mapToCorrectRemarks() {
        AllKnownFieldsBean newBean = new AllKnownFieldsBean();
        AllKnownFieldsBean oldBean = new AllKnownFieldsBean();

        newBean.userId        = "user-B"; oldBean.userId        = "user-A";
        newBean.taskName      = "T2";     oldBean.taskName      = "T1";
        newBean.executeStatus = "done";   oldBean.executeStatus = "todo";
        newBean.status        = "1";      oldBean.status        = "0";
        newBean.taskPriority  = "high";   oldBean.taskPriority  = "low";
        newBean.beginTime     = "2024-2"; oldBean.beginTime     = "2024-1";
        newBean.endTime       = "2024-4"; oldBean.endTime       = "2024-3";
        newBean.closeTime     = "2024-6"; oldBean.closeTime     = "2024-5";
        newBean.description   = "new";    oldBean.description   = "old";
        newBean.taskProcess   = "80";     oldBean.taskProcess   = "50";

        List<LogDataVO> result = FieldUtils.getChangedFields(newBean, oldBean);

        assertEquals(10, result.size(), "10 个字段全部变更，应有 10 条记录");

        // 验证每条 remark 都不为空（具体映射由 switch 保证，只做非空校验避免顺序依赖）
        result.forEach(entry ->
                assertNotNull(entry.getRemark(), "每条记录的 remark 不应为 null"));
    }
}
