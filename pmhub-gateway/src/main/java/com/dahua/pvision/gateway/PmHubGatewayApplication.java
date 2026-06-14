package com.dahua.pvision.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * @description 网关启动程序
 * @create 2024-04-19-17:15
 */
@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})
@EnableDiscoveryClient
public class PmHubGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(PmHubGatewayApplication.class, args);
    }
}
