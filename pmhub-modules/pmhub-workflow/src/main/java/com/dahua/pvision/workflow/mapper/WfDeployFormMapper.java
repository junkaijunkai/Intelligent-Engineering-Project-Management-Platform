package com.dahua.pvision.workflow.mapper;

import com.dahua.pvision.base.core.mapper.BaseMapperPlus;
import com.dahua.pvision.workflow.domain.WfDeployForm;
import com.dahua.pvision.workflow.domain.vo.WfDeployFormVo;
import org.apache.ibatis.annotations.Mapper;

/**
 * 流程实例关联表单Mapper接口
 *
 * @createTime 2022/3/7 22:07
 */
@Mapper
public interface WfDeployFormMapper
        extends BaseMapperPlus<WfDeployFormMapper, WfDeployForm, WfDeployFormVo> {}
