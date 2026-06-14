package com.dahua.pvision.project.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.dahua.pvision.project.domain.vo.project.*;
import com.github.pagehelper.PageInfo;
import com.dahua.pvision.project.domain.Project;
import com.dahua.pvision.project.domain.vo.project.*;
import com.dahua.pvision.project.domain.vo.project.task.TaskStatisticsByDateVO;
import java.util.List;

/**
 * @date 2022-12-13 10:07
 */
public interface ProjectService extends IService<Project> {

    /**
     * 查询所有项目进度排行
     *
     * @return
     */
    List<ProjectRankVO> queryProjectRankList();

    /**
     * 查询与我有关的项目
     *
     * @return
     */
    List<ProjectVO> queryMyProjectList();

    /**
     * 删除项目
     *
     * @param projectVO
     * @return
     */
    int deleteProject(ProjectVO projectVO);

    ProjectResVO detail(String projectId);

    List<DoingProjectVO> queryDoingProject();

    void saveProject(Project project);

    PageInfo<ProjectResVO> list(ProjectReqVO projectReqVO);

    void archived(String projectId);

    void cancelArchived(String projectId);

    void quit(String projectId);

    void editProject(Project project);

    List<TaskStatisticsByDateVO> taskStatisticsByDate(String projectId);

    List<ProjectVO> queryAllProject();

    Long countProjectNum();
}
