package com.dahua.pvision.project.service.file;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.dahua.pvision.base.core.config.PmhubConfig;
import com.dahua.pvision.base.core.core.domain.model.LoginUser;
import com.dahua.pvision.base.core.enums.ProjectStatusEnum;
import com.dahua.pvision.base.core.exception.ServiceException;
import com.dahua.pvision.base.core.utils.file.FileUploadUtils;
import com.dahua.pvision.base.core.utils.file.FileUtils;
import com.dahua.pvision.base.core.utils.file.MimeTypeUtils;
import com.dahua.pvision.project.domain.ProjectFile;
import com.dahua.pvision.project.domain.vo.project.file.FileVO;
import com.dahua.pvision.project.mapper.ProjectFileMapper;
import com.dahua.pvision.project.mapper.ProjectTaskMapper;
import com.dahua.pvision.project.utils.ProjectFileUtil;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * @date 2023-01-09 09:37
 */
@Service("uploadTemplateFileExecutor")
@Slf4j
public class UploadTemplateFileExecutor extends UploadAbstractExecutor {
    @Autowired private ProjectTaskMapper projectTaskMapper;
    @Autowired private ProjectFileMapper projectFileMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FileVO upload(LoginUser user, MultipartFile file, String id) throws Exception {
        log.info("模板上传的的任务id:{}", id);
        String templatePath =
                ProjectFileUtil.uploadTaskFile(
                        PmhubConfig.getTemplatePath(),
                        file,
                        MimeTypeUtils.DEFAULT_ALLOWED_EXTENSION);
        if (StringUtils.isBlank(templatePath)) {
            throw new ServiceException("上传文件异常，请联系管理员");
        }
        // 删除原来的模板
        LambdaQueryWrapper<ProjectFile> lw = new LambdaQueryWrapper<>();
        lw.eq(ProjectFile::getPtId, id)
                .eq(ProjectFile::getType, ProjectStatusEnum.TEMPLATE.getStatusName());
        List<ProjectFile> projectFiles = projectFileMapper.selectList(lw);
        List<String> ids =
                projectFiles.stream().map(ProjectFile::getId).collect(Collectors.toList());
        List<String> fileUrls =
                projectFiles.stream().map(ProjectFile::getPathName).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(ids)) {
            projectFileMapper.deleteBatchIds(ids);
        }
        fileUrls.forEach(FileUtils::deleteFile);

        String pn = ProjectFileUtil.getPathName(PmhubConfig.getTemplatePath(), file);
        ProjectFile projectFile = new ProjectFile();
        projectFile.setFileSize(
                new BigDecimal(String.valueOf(file.getSize()))
                        .divide(new BigDecimal("1024"), 2, RoundingMode.HALF_UP));
        projectFile.setFileName(file.getOriginalFilename());
        projectFile.setFileUrl(templatePath);
        projectFile.setUserId(user.getUserId());
        projectFile.setCreatedBy(user.getUsername());
        projectFile.setCreatedTime(new Date());
        projectFile.setUpdatedBy(user.getUsername());
        projectFile.setUpdatedTime(new Date());
        projectFile.setType(ProjectStatusEnum.TEMPLATE.getStatusName());
        projectFile.setPtId(id);
        projectFile.setExtension(FileUploadUtils.getExtension(file));
        projectFile.setProjectId(projectTaskMapper.selectById(id).getProjectId());
        projectFile.setPathName(pn);
        projectFileMapper.insert(projectFile);

        FileVO fileVO = new FileVO();
        fileVO.setProjectFileId(projectFile.getId());
        fileVO.setFileName(file.getOriginalFilename());
        fileVO.setFileUrl(templatePath);
        return fileVO;
    }
}
