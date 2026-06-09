package com.laigeoffer.pmhub.workflow.mapper;


import com.laigeoffer.pmhub.base.core.mapper.BaseMapperPlus;
import com.laigeoffer.pmhub.workflow.domain.WfCategory;
import com.laigeoffer.pmhub.workflow.domain.vo.WfCategoryVo;
import org.apache.ibatis.annotations.Mapper;

/**
 * 流程分类Mapper接口
 *
 * @author canghe
 * @date 2022-01-15
 */
@Mapper
public interface WfCategoryMapper extends BaseMapperPlus<WfCategoryMapper, WfCategory, WfCategoryVo> {

}
