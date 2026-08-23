## Project Overview

Pvision/PmHub 是面向企业项目协作的项目管理与流程自动化平台。用户可以围绕项目建立阶段、成员、父子任务、进度统计、文件和操作日志，并将项目或任务提交到可配置的 Flowable 审批流程中。系统采用 Vue 前端、Spring Cloud Alibaba 微服务后端和按业务域拆分的 MySQL 数据库，统一通过 Gateway 对外提供 HTTP/JSON API；Nacos 负责服务发现与配置，Redis 负责登录态、缓存和接口级限流。

## Core Modules

- `@pmhub-gateway/src/main/java/com/dahua/pvision/gateway` - 统一入口、路由、JWT/Redis 登录态鉴权、白名单、验证码、黑名单、XSS 和 Sentinel 网关流控；需要排查请求链路、认证、路由或网关限流时参考。
- `@pmhub-auth/src/main/java/com/dahua/pvision/auth` - 登录、退出、刷新 token、注册和密码错误次数控制；需要分析认证流程或 token 生命周期时参考。
- `@pmhub-modules/pmhub-system/src/main/java/com/dahua/pvision/system` - 用户、角色、部门、岗位、菜单、权限、字典、配置、文件、登录/操作日志和在线用户；需要分析身份数据、权限校验或系统管理 API 时参考。
- `@pmhub-modules/pmhub-project/src/main/java/com/dahua/pvision/project` - 项目、阶段、成员、收藏、父子任务、任务状态/进度/工时、文件、评论日志、统计和逾期通知；需要分析核心项目业务或任务拆解时参考。
- `@pmhub-modules/pmhub-workflow/src/main/java/com/dahua/pvision/workflow` - Flowable 模型/表单/分类/部署、项目和任务流程实例、待办/已办/抄送、审批动作、流程图和监听器；需要分析审批链路或工作流状态时参考。
- `@pmhub-modules/pmhub-job/src/main/java/com/dahua/pvision/job` - Quartz 定时任务的增删改查、启停、立即执行和执行日志；需要分析平台级调度时参考。项目域另有任务逾期/提醒 Job，见 project 模块。
- `@pmhub-monitor/src/main/java/com/dahua/pvision/monitor` - Spring Boot Admin 监控中心，端口 6888；需要分析运行时监控时参考，不属于用户业务服务。
- `@pmhub-api/pmhub-api-system` - system 的 Feign 用户/日志远程接口及 FallbackFactory；需要分析认证或跨服务调用边界时参考。
- `@pmhub-api/pmhub-api-workflow` - project 到 workflow 的流程启动、审批设置 Feign 接口及降级实现；需要分析项目与审批服务协作时参考。
- `@pmhub-base/pmhub-base-core` - 统一响应、实体、Redis、JWT、MyBatis-Plus、异常、文件/Excel、线程池和 `@RateLimiter` Redis+Lua 限流；需要复用公共基础能力或定位横切逻辑时参考。
- `@pmhub-base/pmhub-base-security` - Feign 用户上下文透传、权限注解、AOP、Redisson 分布式锁和安全配置；需要分析服务间身份传递、权限或并发控制时参考。
- `@pmhub-base/pmhub-base-notice` - RocketMQ/企业微信通知数据结构与发送工具；需要分析待办、逾期提醒或消息投递时参考。
- `@pmhub-modules/pmhub-gen` - 面向开发人员的表结构到前后端 CRUD 代码生成服务；需要分析代码生成工具时参考，不计入核心用户服务。
- `@pmhub-ui/src/api` - 前端到 Gateway 的 API 清单，按 auth/system/project/workflow/schedule 分组；需要核对前后端接口或页面行为时参考。
- `@sql` - system、project、workflow、gen 四个数据库初始化脚本；需要核对领域表、Flowable 表或数据库边界时参考。
- `@docker` 与 `@sql/pmhub_nacos.sql` - Nacos、MySQL、Redis、Seata、Nginx、服务容器和网关路由的部署配置；需要启动环境、服务端口或 Nacos 路由时参考。
- `@docs/project-notes.md` - 源码通读后的详细业务流程、调用关系、数据模型、配置、API 约定和已知边界；需要深入理解项目或回答跨模块问题时按需参考。
- `@docs/local-startup-and-demo-guide.md` - 微服务版前后端本地启动、数据库与 Nacos 初始化、最小演示服务集、录屏验收和故障排查指南；需要搭建本地演示环境时参考。

## Important Caveats

- 忽略 `@pmhub-boot`，它是单体版本；本项目讨论和后续修改只针对微服务版本。
- `@pmhub-monitor` 是运行时监控中心，不属于用户业务服务；`@pmhub-modules/pmhub-gen` 是开发辅助服务，不属于核心用户业务服务。
- 服务默认端口：gateway 6880、auth 6800、system 6801、gen 6802、job 6803、project 6806、workflow 6808、monitor 6888。
- 跨服务调用优先查看 `@pmhub-api`，服务之间通过 Feign 和服务名调用，不应假设跨库直连。
- 包名重构后必须同步检查 `META-INF/spring.factories` 和 AspectJ 字符串切点；`pmhub-base-security` 已通过 `AutoConfigurationMetadataTest` 覆盖自动配置类加载与鉴权切点解析。
- 本地服务默认以局域网 IP 注册到 Nacos；启用 VPN/TUN 时需将本地网段设为直连，否则 Gateway 访问注册地址可能出现 `Connection prematurely closed` 或 `Connection reset`。
- CI 的 Nacos 初始化通过 `mysql` 客户端执行 `sql/pmhub_nacos.sql`；`DROP/CREATE/USE/SET` 等语句必须保持关键字与参数在同一条语句中，不能按 Navicat 导出格式拆行，否则客户端会提前执行不完整语句。
- CI Compose runtime 会生成隔离配置并将 Nacos、MySQL、Redis 的容器内地址替换为 Compose 服务名；Nacos 数据库内嵌配置中的 `server-addr` 也必须使用 `pmhub-nacos:8848`，不能保留 `127.0.0.1`。
- Compose 中的 Nacos 镜像固定为 `nacos/nacos-server:v2.2.3`，必须与当前 Nacos 2.x SQL schema 和 Spring Cloud Alibaba 2021.x 依赖保持兼容，避免使用漂移的 `latest` 标签。
- 关键发现和后续决策需要继续沉淀到本文件；超过 50 行的细节写入 `@docs/xxx.md`，并在本文件保留索引。
- 处理多任务时，灵活使用sub-agents：按任务间的依赖关系来决定sub-agents是并行执行还是线性执行
- 每次做完写任务后都要：检查代码语法 - 运行相应的测试 - 验证需求已完成，且没有引入回归（不要自我验证、不要信任自己完成的工作，而是让独立的sub-agent来对你完成的工作进行对抗性评估）
