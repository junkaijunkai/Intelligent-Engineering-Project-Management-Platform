package com.dahua.pvision.api.system;

import com.dahua.pvision.api.system.domain.dto.SysUserDTO;
import com.dahua.pvision.api.system.factory.UserFeginFallbackFactory;
import com.dahua.pvision.base.core.constant.SecurityConstants;
import com.dahua.pvision.base.core.constant.ServiceNameConstants;
import com.dahua.pvision.base.core.core.domain.R;
import com.dahua.pvision.base.core.core.domain.entity.SysUser;
import com.dahua.pvision.base.core.core.domain.model.LoginUser;
import com.dahua.pvision.base.core.core.domain.vo.SysUserVO;
import java.util.List;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

/**
 * @description 用户服务
 * @create 2024-04-24-22:38
 */
@FeignClient(
        contextId = "userFeignService",
        value = ServiceNameConstants.SYSTEM_SERVICE,
        fallbackFactory = UserFeginFallbackFactory.class)
public interface UserFeignService {

    /** 根据用户名获取当前用户信息 */
    @GetMapping("/system/user/info/{username}")
    R<LoginUser> info(
            @PathVariable("username") String username,
            @RequestHeader(SecurityConstants.FROM_SOURCE) String source);

    /** 根据 userId 获取用户信息 */
    @GetMapping("/system/user/getInfoByUserId/{userId}")
    R<LoginUser> getInfoByUserId(
            @PathVariable("userId") Long userId,
            @RequestHeader(SecurityConstants.FROM_SOURCE) String source);

    /** 根据条件获取用户列表 */
    @PostMapping("/system/user/listOfInner")
    R<List<SysUserVO>> listOfInner(
            @RequestBody SysUserDTO sysUserDTO,
            @RequestHeader(SecurityConstants.FROM_SOURCE) String source);

    /**
     * 注册用户信息
     *
     * @param sysUser 用户信息
     * @param source 请求来源
     * @return 结果
     */
    @PostMapping("/system/user/register")
    R<Boolean> registerUserInfo(
            @RequestBody SysUser sysUser,
            @RequestHeader(SecurityConstants.FROM_SOURCE) String source);
}
