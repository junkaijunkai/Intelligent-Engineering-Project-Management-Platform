package com.dahua.pvision.workflow.domain.bo;

import com.dahua.pvision.base.core.core.validate.AddGroup;
import com.dahua.pvision.base.core.core.validate.EditGroup;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import lombok.Data;

/**
 * 流程设计业务对象
 *
 * @createTime 2022/3/10 00:12
 */
@Data
public class WfDesignerBo {

    /** 流程名称 */
    @NotNull(
            message = "流程名称",
            groups = {AddGroup.class, EditGroup.class})
    private String name;

    /** 流程分类 */
    @NotBlank(
            message = "流程分类",
            groups = {AddGroup.class, EditGroup.class})
    private String category;

    /** XML字符串 */
    @NotBlank(
            message = "XML字符串",
            groups = {AddGroup.class, EditGroup.class})
    private String xml;
}
