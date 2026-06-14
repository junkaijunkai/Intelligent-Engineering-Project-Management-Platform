package com.dahua.pvision.system.controller;

import com.alibaba.fastjson2.JSONObject;
import com.dahua.pvision.base.core.annotation.Log;
import com.dahua.pvision.base.core.config.redis.RedisService;
import com.dahua.pvision.base.core.constant.CacheConstants;
import com.dahua.pvision.base.core.core.controller.BaseController;
import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.core.domain.model.LoginUser;
import com.dahua.pvision.base.core.core.page.TableDataInfo;
import com.dahua.pvision.base.core.enums.BusinessType;
import com.dahua.pvision.base.core.utils.StringUtils;
import com.dahua.pvision.base.security.annotation.RequiresPermissions;
import com.dahua.pvision.system.domain.SysUserOnline;
import com.dahua.pvision.system.service.ISysUserOnlineService;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/** 在线用户监控 */
@RestController
@RequestMapping("/system/monitor/online")
public class SysUserOnlineController extends BaseController {
    @Autowired private ISysUserOnlineService userOnlineService;

    @Autowired private RedisService redisService;

    @RequiresPermissions("monitor:online:list")
    @GetMapping("/list")
    public TableDataInfo list(String ipaddr, String userName) {
        Collection<String> keys = redisService.keys(CacheConstants.LOGIN_TOKEN_KEY + "*");
        List<SysUserOnline> userOnlineList = new ArrayList<SysUserOnline>();
        for (String key : keys) {
            JSONObject jsonObject = redisService.getCacheObject(key);
            LoginUser user = jsonObject.toJavaObject(LoginUser.class);
            if (StringUtils.isNotEmpty(ipaddr) && StringUtils.isNotEmpty(userName)) {
                if (StringUtils.equals(ipaddr, user.getIpaddr())
                        && StringUtils.equals(userName, user.getUsername())) {
                    userOnlineList.add(
                            userOnlineService.selectOnlineByInfo(ipaddr, userName, user));
                }
            } else if (StringUtils.isNotEmpty(ipaddr)) {
                if (StringUtils.equals(ipaddr, user.getIpaddr())) {
                    userOnlineList.add(userOnlineService.selectOnlineByIpaddr(ipaddr, user));
                }
            } else if (StringUtils.isNotEmpty(userName) && StringUtils.isNotNull(user.getUser())) {
                if (StringUtils.equals(userName, user.getUsername())) {
                    userOnlineList.add(userOnlineService.selectOnlineByUserName(userName, user));
                }
            } else {
                userOnlineList.add(userOnlineService.loginUserToUserOnline(user));
            }
        }
        Collections.reverse(userOnlineList);
        userOnlineList.removeAll(Collections.singleton(null));
        return getDataTable(userOnlineList);
    }

    /** 强退用户 */
    @RequiresPermissions("monitor:online:forceLogout")
    @Log(title = "在线用户", businessType = BusinessType.FORCE)
    @DeleteMapping("/{tokenId}")
    public AjaxResult forceLogout(@PathVariable String tokenId) {
        redisService.deleteObject(CacheConstants.LOGIN_TOKEN_KEY + tokenId);
        return success();
    }
}
