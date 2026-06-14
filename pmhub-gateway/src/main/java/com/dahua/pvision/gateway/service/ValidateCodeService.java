package com.dahua.pvision.gateway.service;

import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.exception.user.CaptchaException;
import java.io.IOException;

/** 验证码处理 */
public interface ValidateCodeService {
    /** 生成验证码 */
    public AjaxResult createCaptcha() throws IOException, CaptchaException;

    /** 校验验证码 */
    public void checkCaptcha(String key, String value) throws CaptchaException;
}
