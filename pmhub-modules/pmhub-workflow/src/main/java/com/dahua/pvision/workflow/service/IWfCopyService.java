package com.dahua.pvision.workflow.service;

import com.dahua.pvision.base.core.core.domain.PageQuery;
import com.dahua.pvision.base.core.core.page.Table2DataInfo;
import com.dahua.pvision.workflow.domain.bo.WfCopyBo;
import com.dahua.pvision.workflow.domain.bo.WfTaskBo;
import com.dahua.pvision.workflow.domain.vo.WfCopyVo;
import java.util.List;

/**
 * 流程抄送Service接口
 *
 * @date 2022-05-19
 */
public interface IWfCopyService {

    /**
     * 查询流程抄送
     *
     * @param copyId 流程抄送主键
     * @return 流程抄送
     */
    WfCopyVo queryById(Long copyId);

    /**
     * 查询流程抄送列表
     *
     * @param wfCopy 流程抄送
     * @return 流程抄送集合
     */
    Table2DataInfo<WfCopyVo> selectPageList(WfCopyBo wfCopy, PageQuery pageQuery);

    /**
     * 查询流程抄送列表
     *
     * @param wfCopy 流程抄送
     * @return 流程抄送集合
     */
    List<WfCopyVo> selectList(WfCopyBo wfCopy);

    /**
     * 抄送
     *
     * @param taskBo
     * @return
     */
    Boolean makeCopy(WfTaskBo taskBo);
}
