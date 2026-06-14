package com.dahua.pvision.project;

import com.dahua.pvision.base.security.annotation.EnableCustomConfig;
import com.dahua.pvision.base.security.annotation.EnablePmFeignClients;
import com.dahua.pvision.base.swagger.annotation.EnableCustomSwagger2;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @description 项目管理模块
 * @create 2024-04-25-17:23
 */
@EnableCustomConfig
@EnablePmFeignClients
@EnableCustomSwagger2
@SpringBootApplication
public class PmHubProjectApplication {
    public static void main(String[] args) {
        SpringApplication.run(PmHubProjectApplication.class, args);
    }
}
