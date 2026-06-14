package com.dahua.pvision.workflow.mapper;

import com.dahua.pvision.base.core.mapper.BaseMapperPlus;
import com.dahua.pvision.workflow.domain.WfCategory;
import com.dahua.pvision.workflow.domain.vo.WfCategoryVo;
import org.apache.ibatis.annotations.Mapper;

/**
 * 流程分类Mapper接口
 *
 * @date 2022-01-15
 */
@Mapper
public interface WfCategoryMapper
        extends BaseMapperPlus<WfCategoryMapper, WfCategory, WfCategoryVo> {}
