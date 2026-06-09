package com.laigeoffer.pmhub.system.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.laigeoffer.pmhub.system.domain.PmhubAsync;
import org.apache.ibatis.annotations.Mapper;

/**
 * 异步任务 数据层
 *
 */
@Mapper
public interface PmhubAsyncMapper extends BaseMapper<PmhubAsync> {

}
