package com.dahua.pvision.workflow;

import com.dahua.pvision.base.security.annotation.EnableCustomConfig;
import com.dahua.pvision.base.security.annotation.EnableDistributedLock;
import com.dahua.pvision.base.security.annotation.EnablePmFeignClients;
import com.dahua.pvision.base.swagger.annotation.EnableCustomSwagger2;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @description 工作流服务
 * @create 2024-04-25-17:45
 */
@EnableCustomConfig
@EnablePmFeignClients
@EnableCustomSwagger2
@EnableDistributedLock // 启用Redisson分布式锁
@SpringBootApplication
public class PmHubWorkflowApplication {
    public static void main(String[] args) {
        SpringApplication.run(PmHubWorkflowApplication.class, args);
    }
}
