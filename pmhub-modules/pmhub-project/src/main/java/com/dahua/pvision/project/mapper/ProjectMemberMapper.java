package com.dahua.pvision.project.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dahua.pvision.project.domain.ProjectMember;
import com.dahua.pvision.project.domain.vo.project.member.ProjectMemberReqVO;
import com.dahua.pvision.project.domain.vo.project.member.ProjectMemberResVO;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * @date 2022-12-12 14:29
 */
@Mapper
public interface ProjectMemberMapper extends BaseMapper<ProjectMember> {

    List<ProjectMemberResVO> searchMember(@Param("data") ProjectMemberReqVO projectMemberReqVO);

    List<ProjectMemberResVO> queryExecutorList(@Param("projectId") String projectId);

    List<ProjectMemberResVO> queryTaskUserList(@Param("taskId") String taskId);
}
