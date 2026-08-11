# Pvision Project Notes

本文档是对微服务版本源码的详细索引。默认忽略 `pmhub-boot` 单体版本。

## 1. Runtime Topology

- Gateway 监听 6880，是前端唯一配置的后端入口。
- Auth 监听 6800，System 监听 6801，Gen 监听 6802，Job 监听 6803。
- Project 监听 6806，Workflow 监听 6808，Monitor 监听 6888。
- 服务通过 Nacos 注册发现和读取配置；网关在 `sql/pmhub_nacos.sql` 中按服务名配置 `lb://` 路由。
- 网关路由前缀主要是 `/auth/**`、`/system/**`、`/project/**`、`/workflow/**`、`/schedule/**` 和 `/gen/**`。
- `/auth/**` 路由会去掉首段后转发，其他主要业务路由保留完整前缀。
- Monitor 使用 Spring Boot Admin；它观察 Spring Cloud 运行时，不承载用户业务。
- Gen 依赖 `gen_table` 和 `gen_table_column`，为开发人员生成 CRUD 代码，不是业务链路必需服务。

## 2. Authentication And Request Context

- 登录入口是 Auth 的 `/login`，登录前不要求业务 token；登录成功后生成 JWT，并将登录用户放入 Redis 登录态。
- Gateway `AuthFilter` 先匹配白名单，再提取 `Authorization: Bearer <token>`，解析 JWT，并校验 Redis 中的登录 token 是否仍然存在。
- 退出登录会根据请求 token 找到用户名，清理 token 并记录登录日志。
- Auth 通过 `UserFeignService` 查询 System 用户信息，通过 `LogFeignService` 保存登录记录。
- Feign `RequestInterceptor` 从当前 HTTP 请求复制用户 ID、用户 key、用户名等安全请求头，防止跨服务调用丢失用户上下文。
- 内部 Feign 接口额外接收 `from-source` 请求头，用于区分内部服务调用；具体接口和降级返回值在 `pmhub-api` 中维护。
- System 负责用户、角色、部门、岗位、菜单、数据权限、字典、配置、在线用户和审计日志。
- System 的菜单数据既用于后台权限，也用于前端动态路由；`/system/menu/getRouters` 是前端登录后的路由入口。
- 文件基础接口在 System 的 `/system/file/**`，项目文件接口在 Project 的 `/project/file/**`，不要将二者视为同一领域。

## 3. Project Domain

- Project 负责项目主数据、项目收藏、成员关系、项目阶段、任务、文件、日志和统计。
- 一个项目可以包含多个阶段；任务通过 `project_stage_id` 关联阶段，通过 `task_pid` 形成父子任务树。
- 任务记录包含优先级、执行人、开始/结束时间、关闭时间、状态、执行状态、进度、审批流程引用和任务类型等信息。
- “任务拆解”在代码中对应新增普通任务和新增子任务，不只是文本描述；它让项目目标落到可分配、可跟踪的任务树上。
- ProjectTaskController 提供我的任务、任务列表、详情、执行人查询、子任务、评论、日志、统计、燃尽图、Excel 导入导出和审批设置接口。
- ProjectController 提供项目新增、编辑、列表、详情、归档/取消归档、退出项目、项目统计、任务列表和发起项目审批接口。
- ProjectMemberController 管理项目成员邀请、移除、列表和执行人查询；用户详细资料通过 System Feign 补齐。
- ProjectLogService 记录项目和任务操作；任务日志查询使用 Factory/Executor 组合按日志类型拼装结果。
- ProjectFileController 支持项目文件列表、上传、重命名、删除、下载和批量下载；上传策略按项目封面、项目文件、任务文件和模板文件分流。
- Project 的定时逻辑包括任务通知、逾期状态更新、逾期提醒和逾期周提醒；它不是 Job 服务中的平台调度 CRUD，但可以由调度能力触发。
- ProjectTaskServiceImpl 使用本地事务处理任务变更；涉及流程或跨服务一致性的代码需要同时检查 Seata 配置和 Workflow Feign 调用。
- Project 与 Workflow 通过 `ProcessFeignService`/`DeployFeignService` 协作，Project 不直接调用 Flowable Engine。

## 4. Workflow Domain

- Workflow 基于 Flowable 6.7.2 数据表和引擎，独立维护运行时、历史、部署、模型、任务、变量和身份关联表。
- 自定义表包括流程分类、表单、模型部署关联、流程表单关联、审批设置、抄送记录、任务消息处理和特定业务流程关联。
- 模型接口负责模型列表、历史版本、BPMN XML、保存、最新版本、删除、导出和部署。
- 部署接口负责已部署流程列表、发布状态、BPMN XML、关联表单和审批设置。
- 流程实例接口负责启动通用流程、项目审批、任务审批、流程详情和实例状态管理。
- 待办工作流支持完成、驳回、退回、退回列表、认领、取消认领、委派、转办、撤回、终止和流程图展示。
- Workflow 通过监听器处理流程开始、结束、取消、任务分配和任务完成等事件；监听器内部再按策略类型选择执行器。
- 流程表单是动态 JSON 配置，模型/部署/表单/审批设置共同决定项目或任务提交后的审批路径。
- 项目审批由 Project 发起，Workflow 创建流程实例；审批完成后需要关注 Workflow listener 和 Project 的流程关联状态更新。
- Workflow 启用了 `EnableDistributedLock`；分布式锁横切实现位于 base-security，使用 Redisson key 前缀、SpEL 动态 key 和 finally 解锁。
- 工作流中的 `@Transactional` 主要保护同一 Workflow 数据库内的审批操作；它不等同于跨服务分布式事务。

## 5. Cross-Service API

- `UserFeignService`：按用户名或用户 ID 查询登录用户，按条件批量查询用户，注册用户信息。
- `LogFeignService`：保存操作日志和登录访问记录。
- `ProcessFeignService`：启动项目流程实例，按流程定义 ID 启动任务流程实例。
- `DeployFeignService`：更新、插入审批设置，查询流程部署关联表单。
- 这些 Feign 接口都配置了 `FallbackFactory`；降级通常返回 `R.fail(...)` 并记录远程异常，不会伪造成功结果。
- Project 查询成员和执行人时调用 UserFeign；Auth 登录和注册调用 UserFeign；Auth 登录日志调用 LogFeign。
- 前端 Axios 默认将请求发往 Gateway，统一使用 JSON 请求；文件上传使用 multipart，下载使用 blob/文件流。
- 前端 API 目录位于 `pmhub-ui/src/api`，页面调用不应绕过 Gateway 直接拼接各服务端口。
- 已存在部分历史遗留前端 API（例如 `/tool/**`、`/storehouse/**`、`/materials-records/**`、`/common/**`），当前微服务目录未发现对应核心 Controller；修改相关页面前需要先确认是否为外部服务或废弃代码。

## 6. Resilience And Security Infrastructure

- Gateway 使用全局 Auth/XSS 过滤器、白名单、验证码、黑名单 URL 和 Sentinel Gateway 流控；Sentinel 规则从 Nacos 的 `sentinel-pmhub-gateway` 读取。
- `@RateLimiter` 是接口级 AOP 限流，key 可按固定 key、类/方法和 IP 组合；Redis Lua 脚本执行计数器和时间窗判断，登录接口示例为 30 秒 10 次。
- 网关流控和注解限流是两层策略：前者保护入口/服务整体流量，后者保护登录等局部敏感接口。
- Redisson 分布式锁提供阻塞加锁和 tryLock 两种模式；无显式 lease time 时依赖 Redisson watchdog 自动续期。
- MyBatis-Plus 统一启用分页、乐观锁和阻断全表更新/删除插件；更新并发问题不应只靠 Redis 锁判断。
- base-core 提供 RedisService、JWT、统一响应 `R`、全局异常、审计注解、重复提交/XSS 过滤、文件和 Excel 工具。
- `EnableCustomConfig` 开启组件扫描、Mapper 扫描、AOP 和异步能力，并导入 Feign 自动配置。
- 公共线程池包含 `threadPoolTaskExecutor`（核心 50、最大 200、队列 1000、CallerRunsPolicy）和定时线程池（核心 50）；这些是线程池上限配置，不代表每个服务启动时已经创建 300 个活跃线程。
- base-notice 提供 RocketMQ 企业微信通知工具，但部分 OA 消息处理代码仍以 TODO/注释形式存在；判断通知是否真正生效时要继续追踪 producer、consumer 和配置。
- base-seata 提供 Seata 依赖；只有标注 `@GlobalTransactional` 且相关数据源/事务组配置生效的调用链才应描述为跨库分布式事务。

## 7. Data And Deployment References

- `sql/pmhub-system.sql`：系统管理库，包含用户、角色、部门、岗位、菜单、字典、配置、通知、登录日志、操作日志、在线会话和系统任务表。
- `sql/pmhub-project.sql`：项目管理库，包含项目、收藏、文件、日志、成员、阶段、任务、任务通知、任务流程和工时表。
- `sql/pmhub-workflow.sql`：Flowable 引擎表以及 PmHub 自定义流程分类、表单、部署、审批、抄送和消息处理表。
- `sql/pmhub-gen.sql`：代码生成元数据表。
- `sql/pmhub_nacos.sql`：Nacos 配置、网关路由、服务公共配置和 Sentinel 持久化规则的初始化数据。
- `docker/docker-compose.yml` 与各服务 Dockerfile 描述 MySQL、Nacos、Redis、Seata、Nginx、Gateway、Auth 和 Monitor 的容器化环境。
- 服务源码中的 `bootstrap.yml` 只提供应用名、端口和 Nacos 地址；业务配置主要从 Nacos 的 profile 配置读取。

## 8. Known Boundaries

- 业务服务通常按 auth、system、project、workflow、job 五类，加 gateway 作为入口；monitor、gen 应按运行支撑/开发辅助单独计数。
- 前端、Gateway、业务服务之间是 HTTP/JSON；服务之间是 Feign over service discovery；服务不应共享业务表或跨库直接写入。
- Project 维护项目/任务业务状态，Workflow 维护流程状态；“任务完成”和“审批完成”不是同一个状态，需要分别查看两侧代码。
- Job 维护 Quartz 调度定义和执行日志；项目逾期 Job 位于 Project，不应因为都带 Job 类就合并为同一服务职责。
- 代码中有部分从 Ruoyi/旧 OA 能力迁移而来的通用接口、注释或前端残留；回答项目能力时以当前 Controller、Service、配置和 SQL 为准。
- 测试目录目前以 base-core 工具测试、代码生成测试和少量 project domain 测试为主，未见覆盖完整登录、网关、审批或跨服务链路的集成测试。

Generated based on `@pmhub-api`, `@pmhub-auth`, `@pmhub-base`, `@pmhub-gateway`, `@pmhub-modules/pmhub-system`, `@pmhub-modules/pmhub-project`, `@pmhub-modules/pmhub-workflow`, `@pmhub-modules/pmhub-job`, `@pmhub-monitor`, `@pmhub-ui`, `@sql`, and `@docker`.
