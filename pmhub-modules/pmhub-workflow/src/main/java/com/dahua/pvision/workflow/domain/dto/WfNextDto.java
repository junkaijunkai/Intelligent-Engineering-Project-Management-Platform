package com.dahua.pvision.workflow.domain.dto;

import com.dahua.pvision.base.core.core.domain.entity.SysRole;
import com.dahua.pvision.base.core.core.domain.entity.SysUser;
import java.io.Serializable;
import java.util.List;
import lombok.Data;

/**
 * 动态人员、组
 *
 * @createTime 2022/3/10 00:12
 */
@Data
public class WfNextDto implements Serializable {

    private String type;

    private String vars;

    private List<SysUser> userList;

    private List<SysRole> roleList;
}
