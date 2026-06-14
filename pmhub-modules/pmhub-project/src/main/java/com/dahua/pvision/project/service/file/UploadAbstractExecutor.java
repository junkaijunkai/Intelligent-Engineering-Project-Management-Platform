package com.dahua.pvision.project.service.file;

import com.dahua.pvision.base.core.core.domain.model.LoginUser;
import com.dahua.pvision.project.domain.vo.project.file.FileVO;
import org.springframework.web.multipart.MultipartFile;

/**
 * @date 2023-01-03 17:22
 */
public abstract class UploadAbstractExecutor {
    public abstract FileVO upload(LoginUser user, MultipartFile file, String id) throws Exception;
}
