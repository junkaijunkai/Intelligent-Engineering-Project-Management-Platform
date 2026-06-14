package com.dahua.pvision.system.controller;

import com.dahua.pvision.base.core.annotation.Log;
import com.dahua.pvision.base.core.core.controller.BaseController;
import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.core.domain.entity.SysOperLog;
import com.dahua.pvision.base.core.core.page.TableDataInfo;
import com.dahua.pvision.base.core.enums.BusinessType;
import com.dahua.pvision.base.core.utils.poi.ExcelUtil;
import com.dahua.pvision.base.security.annotation.RequiresPermissions;
import com.dahua.pvision.system.service.ISysOperLogService;
import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/** 操作日志记录 */
@RestController
@RequestMapping("/system/monitor/operlog")
public class SysOperlogController extends BaseController {
    @Autowired private ISysOperLogService operLogService;

    @RequiresPermissions("monitor:operlog:list")
    @GetMapping("/list")
    public TableDataInfo list(SysOperLog operLog) {
        startPage();
        List<SysOperLog> list = operLogService.selectOperLogList(operLog);
        return getDataTable(list);
    }

    @Log(title = "操作日志", businessType = BusinessType.EXPORT)
    @RequiresPermissions("monitor:operlog:export")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysOperLog operLog) {
        List<SysOperLog> list = operLogService.selectOperLogList(operLog);
        ExcelUtil<SysOperLog> util = new ExcelUtil<SysOperLog>(SysOperLog.class);
        util.exportExcel(response, list, "操作日志");
    }

    @Log(title = "操作日志", businessType = BusinessType.DELETE)
    @RequiresPermissions("monitor:operlog:remove")
    @DeleteMapping("/{operIds}")
    public AjaxResult remove(@PathVariable Long[] operIds) {
        return toAjax(operLogService.deleteOperLogByIds(operIds));
    }

    @Log(title = "操作日志", businessType = BusinessType.CLEAN)
    @RequiresPermissions("monitor:operlog:remove")
    @DeleteMapping("/clean")
    public AjaxResult clean() {
        operLogService.cleanOperLog();
        return success();
    }
}
