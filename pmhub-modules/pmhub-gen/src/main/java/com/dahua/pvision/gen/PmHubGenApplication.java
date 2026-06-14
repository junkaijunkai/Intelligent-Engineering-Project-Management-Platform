package com.dahua.pvision.gen;

import com.dahua.pvision.base.security.annotation.EnableCustomConfig;
import com.dahua.pvision.base.security.annotation.EnablePmFeignClients;
import com.dahua.pvision.base.swagger.annotation.EnableCustomSwagger2;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @description 代码生成
 * @create 2024-04-25-14:18
 */
@EnableCustomConfig
@EnablePmFeignClients
@EnableCustomSwagger2
@SpringBootApplication
public class PmHubGenApplication {
    public static void main(String[] args) {
        SpringApplication.run(PmHubGenApplication.class, args);
    }
}
