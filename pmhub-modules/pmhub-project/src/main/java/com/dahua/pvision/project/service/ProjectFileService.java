package com.dahua.pvision.project.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.dahua.pvision.project.domain.ProjectFile;
import com.dahua.pvision.project.domain.vo.project.file.ProjectFileIdsVO;
import com.dahua.pvision.project.domain.vo.project.file.ProjectFileReqVO;
import com.dahua.pvision.project.domain.vo.project.file.ProjectFileResVO;
import java.io.IOException;
import java.util.List;

/**
 * @date 2022-12-16 09:24
 */
public interface ProjectFileService extends IService<ProjectFile> {

    PageInfo<ProjectFileResVO> queryFileList(ProjectFileReqVO projectFileReqVO);

    void deleteFileList(ProjectFileIdsVO projectFileIdsVO);

    void rename(ProjectFileReqVO projectFileReqVO);

    void batchDownload(String totalZip, List<String> paths) throws IOException;
}
