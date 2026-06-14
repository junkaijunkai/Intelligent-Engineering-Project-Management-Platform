package com.dahua.pvision.project.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.dahua.pvision.project.domain.ProjectLog;
import com.dahua.pvision.project.domain.vo.project.ProjectVO;
import com.dahua.pvision.project.domain.vo.project.log.LogVO;
import com.dahua.pvision.project.domain.vo.project.log.ProjectLogVO;

/**
 * @date 2022-12-21 11:40
 */
public interface ProjectLogService extends IService<ProjectLog> {
    void run(LogVO logVO);

    PageInfo<ProjectLogVO> list(ProjectVO projectVO);
}
