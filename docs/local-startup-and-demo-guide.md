# Pvision 前后端本地启动与演示录制指南

本文面向“在本机启动微服务版 Pvision，并录制前端演示”的场景。不要启动 `pmhub-boot`；它是单体版本。

## 1. 推荐启动范围

录制项目、任务和审批流程时，建议启动以下组件：

| 类型 | 组件 | 端口 | 是否必需 |
| --- | --- | ---: | --- |
| 基础设施 | MySQL 5.7 | 3306 | 必需 |
| 基础设施 | Redis | 6379 | 必需 |
| 基础设施 | Nacos 2.x | 8848 | 必需 |
| 分布式事务 | Seata 1.5.2 | 8091 | 创建任务时建议启动 |
| 后端 | System | 6801 | 必需 |
| 后端 | Project | 6806 | 必需 |
| 后端 | Workflow | 6808 | 录制审批时必需 |
| 后端 | Auth | 6800 | 必需 |
| 后端 | Gateway | 6880 | 必需 |
| 前端 | Vue 开发服务器 | 建议 8080 | 必需 |

`pmhub-monitor`、`pmhub-gen`、`pmhub-job` 不属于这次演示的最小启动范围。RocketMQ、FastDFS 也不是浏览核心页面和演示基础项目流程的前置条件。

## 2. 环境版本

- JDK：项目目标版本为 Java 8；本地推荐使用 JDK 8 或 17。
- Maven：3.6 及以上。
- Node.js：使用仓库指定的 `v16.18.1`，不要直接使用 Node 26。
- npm：随 Node 16 安装的版本即可。
- MySQL：5.7，字符集建议 `utf8mb4`。
- Nacos：2.x，账号密码默认按 `nacos / nacos` 配置。
- Redis：本地开发配置默认无密码。

检查版本：

```bash
java -version
mvn -version
node -v
npm -v
```

如果使用 nvm：

```bash
cd pmhub-ui
nvm install 16.18.1
nvm use 16.18.1
```

## 3. 首次初始化数据库

仓库中的 Nacos 配置默认连接 `127.0.0.1:3306`，业务库账号为 `root`，密码为 `123456`。最省事的做法是让本地 MySQL 与这个配置保持一致；如果使用其他端口或密码，必须同步修改 Nacos 中各服务的配置。

在仓库根目录执行：

```bash
mysql -uroot -p123456 < sql/pmhub-system.sql
mysql -uroot -p123456 < sql/pmhub-project.sql
mysql -uroot -p123456 < sql/pmhub-workflow.sql
mysql -uroot -p123456 < sql/pmhub_nacos.sql
```

如果要稳定演示“创建任务”涉及的 Seata 分布式事务，再执行：

```bash
mysql -uroot -p123456 < sql/pmhub_seata.sql
```

注意：这些脚本用于首次建库。业务 SQL 包含 `CREATE DATABASE`，已有同名库时不要盲目重复执行，先备份或确认可以重建。

初始化完成后至少应存在：

```text
pmhub-system
pmhub-project
pmhub-workflow
pmhub-nacos
pmhub-seata        # 使用 Seata 时
```

## 4. 启动基础设施

### 4.1 Redis

确保 `127.0.0.1:6379` 可访问且无密码。验证：

```bash
redis-cli ping
```

预期返回 `PONG`。

### 4.2 Nacos

使用 Nacos 的 MySQL 数据源，并将 Nacos 安装目录中的 `conf/application.properties` 配置为：

```properties
spring.datasource.platform=mysql
db.num=1
db.url.0=jdbc:mysql://127.0.0.1:3306/pmhub-nacos?characterEncoding=utf8&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai
db.user=root
db.password=123456
```

然后启动单机模式：

```bash
sh bin/startup.sh -m standalone
```

打开 `http://127.0.0.1:8848/nacos`，登录后在“配置管理”确认至少存在以下 Data ID：

```text
application-dev.yml
pmhub-gateway-dev.yml
pmhub-auth-dev.yml
pmhub-system-dev.yml
pmhub-project-dev.yml
pmhub-workflow-dev.yml
```

逐项检查业务服务配置中的 MySQL 地址、用户名和密码；还要确认 Redis 地址是 `127.0.0.1:6379`。

### 4.3 Seata（录制创建任务时建议启动）

将 Seata 配置为：

- 注册中心：Nacos `127.0.0.1:8848`；
- 服务名：`seata-server`；
- 分组：`SEATA_GROUP`；
- 数据库：`pmhub-seata`；
- 端口：`8091`。

启动后，在 Nacos 服务列表确认 `seata-server` 已注册。只浏览项目列表时可以不启动 Seata；录制新建任务前应启动，否则 `@GlobalTransactional` 操作可能重试或失败。

### 4.4 关于仓库 Docker Compose 的重要说明

`docker/docker-compose.yml` 当前不能作为“首次拉起即用”的方案：

- MySQL 初始化脚本在 Dockerfile 中默认被注释，不会自动建业务库；
- MySQL 对宿主机暴露的是 `33706`，而 Nacos 业务配置使用 `3306`；
- Compose 中的 MySQL root 密码与 Nacos/业务配置可能不一致；
- 容器内的 `localhost` 指向容器自身，不指向 `pmhub-mysql`。

如果坚持使用 Compose，必须先统一容器网络地址、端口和密码，并手工导入上述 SQL。为了尽快完成录屏，优先采用“基础设施可访问 + Java 服务在本机运行”的方式。

## 5. 构建后端

首次启动前，在仓库根目录安装所有 Maven 模块：

```bash
mvn clean install -DskipTests -Ddependency-check.skip=true
```

如果 IDE 仍然提示找不到内部模块，重新加载根目录 `pom.xml`，不要只导入某一个业务模块。

## 6. 启动后端服务

推荐在 IntelliJ IDEA 中分别运行以下主类，启动顺序如下：

1. `com.dahua.pvision.system.PmHubSystemApplication`
2. `com.dahua.pvision.project.PmHubProjectApplication`
3. `com.dahua.pvision.workflow.PmHubWorkflowApplication`
4. `com.dahua.pvision.auth.PmHubAuthApplication`
5. `com.dahua.pvision.gateway.PmHubGatewayApplication`

也可以开五个终端，在完成根项目 `mvn install` 后分别执行：

```bash
mvn -f pmhub-modules/pmhub-system/pom.xml spring-boot:run -Dspring-boot.run.profiles=dev
mvn -f pmhub-modules/pmhub-project/pom.xml spring-boot:run -Dspring-boot.run.profiles=dev
mvn -f pmhub-modules/pmhub-workflow/pom.xml spring-boot:run -Dspring-boot.run.profiles=dev
mvn -f pmhub-auth/pom.xml spring-boot:run -Dspring-boot.run.profiles=dev
mvn -f pmhub-gateway/pom.xml spring-boot:run -Dspring-boot.run.profiles=dev
```

这里必须显式传入 `dev`。各微服务的 `bootstrap.yml` 当前将
`spring.profiles.active` 写成 `${spring.profiles.active:dev}`；没有外部 profile 时，
Spring Boot 2.7 会把它识别为属性对自身的循环引用并中止启动。

每个服务看到类似 `Started ...Application` 后，再检查 Nacos 服务列表。应能看到：

```text
pmhub-system
pmhub-project
pmhub-workflow
pmhub-auth
pmhub-gateway
```

不要只看进程是否存在；服务没有注册到 Nacos 时，Gateway 仍然会返回 `503`。

## 7. 启动前端

前端开发配置把 `/dev-api` 代理到 `http://127.0.0.1:6880`。建议把前端端口设为 8080，避免 macOS/Linux 上使用 80 端口时需要管理员权限。

```bash
cd pmhub-ui
nvm use 16.18.1
npm install
port=8080 npm run dev
```

打开：

```text
http://127.0.0.1:8080
```

如果一定要使用默认端口，直接执行 `npm run dev`；`vue.config.js` 的默认端口是 80。

## 8. 登录账号准备

初始化 SQL 中存在启用状态的超级管理员 `admin`，但仓库只保存 BCrypt 密文，没有可靠的明文密码说明。录制前不要临场猜密码，建议提前确认已有密码，或仅在本地演示库中重置为一个临时密码。

例如，下面的 SQL 将本地 `admin` 密码重置为 `123456`：

```sql
USE `pmhub-system`;
UPDATE sys_user
SET password = '$2y$10$anflHPfL0nPiY8CBihTFlu3NgVsPhNxIQsxkzdY4HuHqYQRwEqn46'
WHERE user_name = 'admin';
```

该密码只适合本地演示。录制结束后不要把它用于任何联网或共享环境。

## 9. 录制前验收清单

按以下顺序检查，全部通过后再开始录屏：

1. `redis-cli ping` 返回 `PONG`。
2. Nacos 控制台能看到 5 个后端服务和 Seata（如使用）。
3. 五个 Java 控制台都没有持续刷连接数据库、Redis、Nacos 或 Seata 的错误。
4. 打开前端后，浏览器 Network 中 `/dev-api/...` 请求不是 `502/503`。
5. 使用演示账号完成一次登录、退出、重新登录。
6. 提前创建一套演示项目、阶段、成员和任务，避免空页面。
7. 如果演示审批，提前确认存在已部署的流程模型，并测试一次提交、审批和流程图查看。
8. 清除无关浏览器标签、通知和敏感数据；浏览器缩放建议 90% 或 100%。
9. 正式录制前完整走一遍：登录 → 工作台 → 项目 → 任务 → 审批 → 统计。

## 10. 建议演示路径

一条比较顺畅的 5～8 分钟演示路线：

1. 登录并展示工作台统计。
2. 打开项目列表，展示项目状态、收藏和成员。
3. 进入一个预置项目，展示阶段、父子任务、负责人、进度与工时。
4. 新建或修改一个任务，展示任务日志和评论。
5. 提交项目或任务审批，切换到待办/已办，完成一次审批动作。
6. 返回项目查看流程状态，再展示统计页面作为收尾。

为了降低录制风险，正式录制时优先使用预置数据；“新建任务”和“提交审批”各保留一次实时操作即可。

## 11. 常见故障

### 前端启动时报 OpenSSL 或 webpack 错误

确认使用 Node `16.18.1`。仓库虽然设置了 `--openssl-legacy-provider`，但 Node 过新仍可能带来依赖兼容问题。

### 前端启动时报 80 端口权限不足或被占用

使用：

```bash
port=8080 npm run dev
```

### 登录接口返回 503

检查 Nacos 中是否同时存在 `pmhub-auth` 和 `pmhub-system`。登录服务会通过 Feign 调用 System，缺少任何一个都不能正常登录。

### 页面能打开但接口 404

确认前端使用 development 模式，接口前缀应为 `/dev-api`；`vue.config.js` 会把该前缀去掉后转发到 Gateway `6880`。

### 服务启动时报数据库连接失败

检查 Nacos 对应 Data ID，而不是只检查服务源码里的 `bootstrap.yml`。源码只保存端口、应用名和 Nacos 地址，数据库配置来自 Nacos。

### 服务启动时报 Circular placeholder reference

启动命令没有显式传入 profile。Maven 启动时添加：

```bash
-Dspring-boot.run.profiles=dev
```

IDEA 启动时则在 Run Configuration 中设置 `Active profiles` 为 `dev`，或在 VM options 中加入 `-Dspring.profiles.active=dev`。

### 新建任务失败并出现 Seata 错误

确认 `pmhub-seata` 数据库已初始化、Seata Server 已启动并注册为 `seata-server`，同时检查 `pmhub-project-dev.yml` 的事务组映射。

### Workflow 启动时报表不存在

重新确认 `sql/pmhub-workflow.sql` 已完整导入。该脚本包含 Flowable 的 `ACT_*`、`FLW_*` 表和 Pvision 工作流业务表。

## 12. 停止顺序

录制完成后先停止前端，再停止 Gateway、Auth、Workflow、Project、System，最后停止 Seata、Nacos、Redis 和 MySQL。不要在录制过程中重启 Redis，否则登录态会丢失。

Generated based on `@pmhub-ui/package.json`, `@pmhub-ui/.node-version`, `@pmhub-ui/vue.config.js`, `@pmhub-*/src/main/resources/bootstrap.yml`, `@sql`, `@docker`, `@pom.xml`, `@docs/project-notes.md`.
