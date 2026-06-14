package com.dahua.pvision.project.service.task;

import com.dahua.pvision.project.domain.vo.project.log.ProjectLogVO;
import java.util.List;

/**
 * @date 2023-01-09 16:21
 */
public abstract class QueryLogAbstractExecutor {

    public abstract List<ProjectLogVO> query(String taskId);
}
