package com.dahua.pvision.base.security.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.alibaba.fastjson2.JSONObject;
import com.dahua.pvision.base.core.core.domain.model.LoginUser;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

class TokenServiceTest {

    private final TokenService tokenService = new TokenService();

    @Test
    void convertsLoginUserWithoutRecasting() {
        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(173L);

        assertEquals(loginUser, tokenService.convertToLoginUser(loginUser));
    }

    @Test
    void convertsJsonObjectToLoginUser() {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("userId", 173L);

        LoginUser loginUser = tokenService.convertToLoginUser(jsonObject);

        assertEquals(173L, loginUser.getUserId());
    }

    @Test
    void convertsMapToLoginUser() {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", 173L);

        LoginUser loginUser = tokenService.convertToLoginUser(map);

        assertEquals(173L, loginUser.getUserId());
    }

    @Test
    void returnsNullForUnsupportedType() {
        assertNull(tokenService.convertToLoginUser("not-a-login-user"));
    }
}
