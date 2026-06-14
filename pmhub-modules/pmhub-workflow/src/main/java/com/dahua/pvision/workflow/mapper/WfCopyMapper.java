package com.dahua.pvision.workflow.mapper;

import com.dahua.pvision.base.core.core.domain.entity.SysDept;
import com.dahua.pvision.base.core.core.domain.entity.SysRole;
import com.dahua.pvision.base.core.core.domain.entity.SysUser;
import com.dahua.pvision.base.core.mapper.BaseMapperPlus;
import com.dahua.pvision.workflow.domain.WfCopy;
import com.dahua.pvision.workflow.domain.vo.WfCopyVo;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 流程抄送Mapper接口
 *
 * @date 2022-05-19
 */
@Mapper
public interface WfCopyMapper extends BaseMapperPlus<WfCopyMapper, WfCopy, WfCopyVo> {

    SysUser selectUserById(@Param("userId") Long userId);

    SysRole selectRoleById(@Param("roleId") Long roleId);

    SysDept selectDeptById(@Param("deptId") Long deptId);

    List<Long> selectUserIdsByRoleId(@Param("roleId") Long roleId);

    List<Long> selectUserIds(@Param("deptIds") List<String> deptIds);
}
