package com.dahua.pvision.base.notice.domain.dto;

import java.io.Serializable;
import lombok.Data;

/**
 * @date 2023-04-10 10:59
 */
@Data
public class MessageDataDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private String msgCode;
    private Long msgTime;
    private String wxUserName;
}
