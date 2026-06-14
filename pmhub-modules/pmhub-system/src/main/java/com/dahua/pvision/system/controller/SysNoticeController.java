package com.dahua.pvision.system.controller;

import com.dahua.pvision.base.core.annotation.Log;
import com.dahua.pvision.base.core.core.controller.BaseController;
import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.core.page.TableDataInfo;
import com.dahua.pvision.base.core.enums.BusinessType;
import com.dahua.pvision.base.security.annotation.RequiresPermissions;
import com.dahua.pvision.base.security.utils.SecurityUtils;
import com.dahua.pvision.system.domain.SysNotice;
import com.dahua.pvision.system.service.ISysNoticeService;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

/** 公告 信息操作处理 */
@RestController
@RequestMapping("/system/notice")
public class SysNoticeController extends BaseController {
    @Autowired private ISysNoticeService noticeService;

    /** 获取通知公告列表 */
    @RequiresPermissions("system:notice:list")
    @GetMapping("/list")
    public TableDataInfo list(SysNotice notice) {
        startPage();
        List<SysNotice> list = noticeService.selectNoticeList(notice);
        return getDataTable(list);
    }

    /** 根据通知公告编号获取详细信息 */
    @RequiresPermissions("system:notice:query")
    @GetMapping(value = "/{noticeId}")
    public AjaxResult getInfo(@PathVariable Long noticeId) {
        return success(noticeService.selectNoticeById(noticeId));
    }

    /** 新增通知公告 */
    @RequiresPermissions("system:notice:add")
    @Log(title = "通知公告", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@Validated @RequestBody SysNotice notice) {
        notice.setCreateBy(SecurityUtils.getUsername());
        return toAjax(noticeService.insertNotice(notice));
    }

    /** 修改通知公告 */
    @RequiresPermissions("system:notice:edit")
    @Log(title = "通知公告", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@Validated @RequestBody SysNotice notice) {
        notice.setUpdateBy(SecurityUtils.getUsername());
        return toAjax(noticeService.updateNotice(notice));
    }

    /** 删除通知公告 */
    @RequiresPermissions("system:notice:remove")
    @Log(title = "通知公告", businessType = BusinessType.DELETE)
    @DeleteMapping("/{noticeIds}")
    public AjaxResult remove(@PathVariable Long[] noticeIds) {
        return toAjax(noticeService.deleteNoticeByIds(noticeIds));
    }
}
