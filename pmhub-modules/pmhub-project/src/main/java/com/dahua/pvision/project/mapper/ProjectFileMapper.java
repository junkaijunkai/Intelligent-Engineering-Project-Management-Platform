package com.dahua.pvision.project.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.dahua.pvision.project.domain.ProjectFile;
import com.dahua.pvision.project.domain.vo.project.file.ProjectFileReqVO;
import com.dahua.pvision.project.domain.vo.project.file.ProjectFileResVO;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * @date 2022-12-12 14:28
 */
@Mapper
public interface ProjectFileMapper extends BaseMapper<ProjectFile> {

    List<ProjectFileResVO> queryFileList(@Param("data") ProjectFileReqVO projectFileReqVO);

    List<ProjectFileResVO> queryProjectFileList(@Param("data") ProjectFileReqVO projectFileReqVO);

    List<ProjectFileResVO> queryTaskFileList(@Param("data") ProjectFileReqVO projectFileReqVO);

    List<ProjectFileResVO> queryTemplateFileList(@Param("data") ProjectFileReqVO projectFileReqVO);
}
