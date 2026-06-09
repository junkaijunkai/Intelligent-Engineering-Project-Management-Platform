package com.laigeoffer.pmhub.workflow.mapper;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.core.toolkit.Constants;
import com.laigeoffer.pmhub.base.core.mapper.BaseMapperPlus;
import com.laigeoffer.pmhub.workflow.domain.WfForm;
import com.laigeoffer.pmhub.workflow.domain.vo.WfFormVo;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 流程表单Mapper接口
 *
 * @createTime 2022/3/7 22:07
 */
@Mapper
public interface WfFormMapper extends BaseMapperPlus<WfFormMapper, WfForm, WfFormVo> {

    List<WfFormVo> selectFormVoList(@Param(Constants.WRAPPER) Wrapper<WfForm> queryWrapper);
}
