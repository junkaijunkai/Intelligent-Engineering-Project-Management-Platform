package com.dahua.pvision.system.controller;

import com.dahua.pvision.base.core.annotation.Log;
import com.dahua.pvision.base.core.config.redis.RedisService;
import com.dahua.pvision.base.core.constant.CacheConstants;
import com.dahua.pvision.base.core.core.controller.BaseController;
import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.core.domain.entity.SysLogininfor;
import com.dahua.pvision.base.core.core.page.TableDataInfo;
import com.dahua.pvision.base.core.enums.BusinessType;
import com.dahua.pvision.base.core.utils.poi.ExcelUtil;
import com.dahua.pvision.base.security.annotation.InnerAuth;
import com.dahua.pvision.base.security.annotation.RequiresPermissions;
import com.dahua.pvision.system.service.ISysLogininforService;
import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/** 系统访问记录 */
@RestController
@RequestMapping("/system/monitor/logininfor")
public class SysLogininforController extends BaseController {
    @Autowired private ISysLogininforService logininforService;

    @Autowired private RedisService redisService;

    @RequiresPermissions("@ss.hasPermi('monitor:logininfor:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysLogininfor logininfor) {
        startPage();
        List<SysLogininfor> list = logininforService.selectLogininforList(logininfor);
        return getDataTable(list);
    }

    @Log(title = "登录日志", businessType = BusinessType.EXPORT)
    @RequiresPermissions("monitor:logininfor:export")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysLogininfor logininfor) {
        List<SysLogininfor> list = logininforService.selectLogininforList(logininfor);
        ExcelUtil<SysLogininfor> util = new ExcelUtil<SysLogininfor>(SysLogininfor.class);
        util.exportExcel(response, list, "登录日志");
    }

    @RequiresPermissions("monitor:logininfor:remove")
    @Log(title = "登录日志", businessType = BusinessType.DELETE)
    @DeleteMapping("/{infoIds}")
    public AjaxResult remove(@PathVariable Long[] infoIds) {
        return toAjax(logininforService.deleteLogininforByIds(infoIds));
    }

    @RequiresPermissions("monitor:logininfor:remove")
    @Log(title = "登录日志", businessType = BusinessType.CLEAN)
    @DeleteMapping("/clean")
    public AjaxResult clean() {
        logininforService.cleanLogininfor();
        return success();
    }

    @RequiresPermissions("onitor:logininfor:unlock")
    @Log(title = "账户解锁", businessType = BusinessType.OTHER)
    @GetMapping("/unlock/{userName}")
    public AjaxResult unlock(@PathVariable("userName") String userName) {
        redisService.deleteObject(CacheConstants.PWD_ERR_CNT_KEY + userName);
        return success();
    }

    /**
     * 插入访问记录-内部微服务调用
     *
     * @param logininfor
     * @return
     */
    @InnerAuth
    @PostMapping
    public AjaxResult add(@RequestBody SysLogininfor logininfor) {
        return toAjax(logininforService.insertLogininfor(logininfor));
    }
}
