package com.dahua.pvision.system.controller;

import com.dahua.pvision.base.core.annotation.Log;
import com.dahua.pvision.base.core.core.controller.BaseController;
import com.dahua.pvision.base.core.core.domain.AjaxResult;
import com.dahua.pvision.base.core.core.domain.entity.SysDictData;
import com.dahua.pvision.base.core.core.page.TableDataInfo;
import com.dahua.pvision.base.core.enums.BusinessType;
import com.dahua.pvision.base.core.utils.StringUtils;
import com.dahua.pvision.base.core.utils.poi.ExcelUtil;
import com.dahua.pvision.base.security.annotation.RequiresPermissions;
import com.dahua.pvision.base.security.utils.SecurityUtils;
import com.dahua.pvision.system.service.ISysDictDataService;
import com.dahua.pvision.system.service.ISysDictTypeService;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

/** 数据字典信息 */
@RestController
@RequestMapping("/system/dict/data")
public class SysDictDataController extends BaseController {
    @Autowired private ISysDictDataService dictDataService;

    @Autowired private ISysDictTypeService dictTypeService;

    @RequiresPermissions("system:dict:list")
    @GetMapping("/list")
    public TableDataInfo list(SysDictData dictData) {
        startPage();
        List<SysDictData> list = dictDataService.selectDictDataList(dictData);
        return getDataTable(list);
    }

    @GetMapping("/varList")
    public AjaxResult varList() {
        return AjaxResult.success(dictDataService.selectDictDataList());
    }

    @Log(title = "字典数据", businessType = BusinessType.EXPORT)
    @RequiresPermissions("system:dict:export")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysDictData dictData) {
        List<SysDictData> list = dictDataService.selectDictDataList(dictData);
        ExcelUtil<SysDictData> util = new ExcelUtil<SysDictData>(SysDictData.class);
        util.exportExcel(response, list, "字典数据");
    }

    /** 查询字典数据详细 */
    @RequiresPermissions("system:dict:query")
    @GetMapping(value = "/{dictCode}")
    public AjaxResult getInfo(@PathVariable Long dictCode) {
        return success(dictDataService.selectDictDataById(dictCode));
    }

    /** 根据字典类型查询字典数据信息 */
    @GetMapping(value = "/type/{dictType}")
    public AjaxResult dictType(@PathVariable String dictType) {
        List<SysDictData> data = dictTypeService.selectDictDataByType(dictType);
        if (StringUtils.isNull(data)) {
            data = new ArrayList<SysDictData>();
        }
        return success(data);
    }

    /** 新增字典类型 */
    @RequiresPermissions("system:dict:add")
    @Log(title = "字典数据", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@Validated @RequestBody SysDictData dict) {
        dict.setCreateBy(SecurityUtils.getUsername());
        return toAjax(dictDataService.insertDictData(dict));
    }

    /** 修改保存字典类型 */
    @RequiresPermissions("system:dict:edit")
    @Log(title = "字典数据", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@Validated @RequestBody SysDictData dict) {
        dict.setUpdateBy(SecurityUtils.getUsername());
        return toAjax(dictDataService.updateDictData(dict));
    }

    /** 删除字典类型 */
    @RequiresPermissions("system:dict:remove")
    @Log(title = "字典类型", businessType = BusinessType.DELETE)
    @DeleteMapping("/{dictCodes}")
    public AjaxResult remove(@PathVariable Long[] dictCodes) {
        dictDataService.deleteDictDataByIds(dictCodes);
        return success();
    }
}
