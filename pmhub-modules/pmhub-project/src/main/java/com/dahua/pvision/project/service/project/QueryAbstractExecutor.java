package com.dahua.pvision.project.service.project;

import com.dahua.pvision.project.domain.vo.project.ProjectReqVO;
import com.dahua.pvision.project.domain.vo.project.ProjectResVO;
import java.util.List;

/**
 * @date 2023-01-09 11:41
 */
public abstract class QueryAbstractExecutor {
    public abstract List<ProjectResVO> query(ProjectReqVO projectReqVO);
}
