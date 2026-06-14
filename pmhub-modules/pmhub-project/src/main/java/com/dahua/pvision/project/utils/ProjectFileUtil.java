package com.dahua.pvision.project.utils;

import com.dahua.pvision.base.core.exception.file.FileNameLengthLimitExceededException;
import com.dahua.pvision.base.core.exception.file.FileSizeLimitExceededException;
import com.dahua.pvision.base.core.exception.file.InvalidExtensionException;
import com.dahua.pvision.base.core.utils.file.FileUploadUtils;
import com.dahua.pvision.base.security.utils.SecurityUtils;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.Objects;
import org.springframework.web.multipart.MultipartFile;

/**
 * @description ProjectFileUtil
 * @create 2024-05-15-16:26
 */
public class ProjectFileUtil {
    public static String uploadProjectFile(
            String baseDir, MultipartFile file, String[] allowedExtension)
            throws FileSizeLimitExceededException,
                    IOException,
                    FileNameLengthLimitExceededException,
                    InvalidExtensionException {

        if (Objects.requireNonNull(file.getOriginalFilename()).length()
                > FileUploadUtils.DEFAULT_FILE_NAME_LENGTH) {
            throw new FileNameLengthLimitExceededException(
                    FileUploadUtils.DEFAULT_FILE_NAME_LENGTH);
        }

        FileUploadUtils.assertAllowed(file, allowedExtension);

        String fileName = FileUploadUtils.extractFileName(SecurityUtils.getUsername(), file);

        String absPath = FileUploadUtils.getAbsoluteFile(baseDir, fileName).getAbsolutePath();
        file.transferTo(Paths.get(absPath));
        return FileUploadUtils.getPathFileName(baseDir, fileName);
    }

    public static String uploadTaskFile(
            String baseDir, MultipartFile file, String[] allowedExtension)
            throws FileSizeLimitExceededException,
                    IOException,
                    FileNameLengthLimitExceededException,
                    InvalidExtensionException {

        int fileNameLength = Objects.requireNonNull(file.getOriginalFilename()).length();
        if (fileNameLength > FileUploadUtils.DEFAULT_FILE_NAME_LENGTH) {
            throw new FileNameLengthLimitExceededException(
                    FileUploadUtils.DEFAULT_FILE_NAME_LENGTH);
        }

        FileUploadUtils.assertAllowed(file, allowedExtension);

        String fileName = FileUploadUtils.extractFileName(SecurityUtils.getUsername(), file);

        String absPath = FileUploadUtils.getAbsoluteFile(baseDir, fileName).getAbsolutePath();
        file.transferTo(Paths.get(absPath));
        return FileUploadUtils.getPathFileName(baseDir, fileName);
    }

    public static String getPathName(String uploadDir, MultipartFile file) throws IOException {
        String fileName = FileUploadUtils.extractFileName(SecurityUtils.getUsername(), file);
        return uploadDir + "/" + fileName;
    }
}
