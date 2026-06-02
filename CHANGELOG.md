# Changelog

## v0.1.0 (2026-06-01)

### 系统性改进

#### 日志系统统一
- Daemon 生产代码 printf 全部迁移至 SVC_LOG_* 宏（781 处清零）
- 7 个 daemon 服务 main.c 补全 svc_log_init() 日志初始化
- 创建统一日志接口 logger.h，定义 AGENTOS_LOG_* 和 SVC_LOG_* 两套宏
- Commons utils/logging 提供 log_write() 统一写入路径

#### 内存管理全覆盖
- AgentOS 全项目原始 malloc/free/calloc/realloc 调用迁移至 AGENTOS_* 宏（~588 处完成）
- Daemon 生产代码 raw malloc/free 清零
- 关键文件迁移：mcp_v1_adapter.c (117 calls)、cupolas_vault.c (110 calls)、scheduler.c (71 calls)
- memory_compat.h 提供 AGENTOS_MALLOC/AGENTOS_FREE 等内存跟踪宏

#### CI/CD 质量门禁修复
- 移除所有 CI workflow 中的 `|| true` 绕过（Desktop 4 处、Docker 7 处、e2e 1 处）
- BUILD_TESTS 默认值 OFF → ON（4 个 CMakeLists.txt）
- strict build 模式启用（poisoned functions 拦截：fprintf、malloc、free 等）
- e2e.yml 移除 critical 步骤的 continue-on-error

#### 版本号统一
- 全项目版本号统一至 Semver 3 位 v0.1.0
- AgentOS CMakeLists.txt: 0.1.0
- Desktop package.json: 0.1.0
- 修正 daemon 子服务 3.0.0、protocols 2.1.0、4 位版本号遗存

### 新增功能

#### Desktop 前端 (React + TypeScript + Tauri)
- AI 聊天界面 (AIChat) — 消息列表、输入框、发送按钮
- 命令面板 (CommandPalette) — Cmd/Ctrl+K 快捷键、命令搜索
- 全局搜索 (GlobalSearch) — 跨页面搜索、结果预览、键盘导航
- 系统设置 (Settings) — 主题切换、API 配置、日志级别、语言
- 认知循环监控 (CognitiveLoop) — 实时任务状态显示
- 安全中心 (SecurityCenter) — API Key 管理、审计日志
- 会话管理、任务管理、工具管理器、Agent 管理、模型配置面板

#### AgentOS 核心
- HNSW 图遍历检索实现（O(log n)，替代暴力搜索 O(n)）
- 任务 ID 正确返回（loop_submit() 修复）
- 认知引擎 context_processor extern 声明规范化
- config_source.c 文件句柄成员验证

#### MemoryRovol 内存系统
- HNSW 分层图遍历检索（正确实现 O(log n) 搜索）
- Builtin memory provider 能力诚实声明（l2_feature=0）

### 安全加固

- rand() → /dev/urandom 安全随机数（browser.c）
- CORS_ORIGINS=* → 安全默认值（.env.example）
- JSON 注入防护（openai_enterprise_adapter.c json_escape_string）
- DANGEROUS_PATTERNS 优化拆分（security.py）
- 3 处 registry 竞态条件修复（tool_d/llm_d/sched_d）
- Dockerfile.kernel CUDA 路径 ARG 化

### Bug 修复

- #elif 嵌套预处理器错误修复（advanced_message_builder.c）
- CLI f-string 括号不匹配修复（agentos/cli/main.py）
- Python SDK TimeoutError/MemoryError 重命名避免覆盖内置异常
- Docker 部署路径 deploy/ → deployment/ 修正
- Docker IPAM 配置字段 ipam.manager → ipam.config 修正
- OpenLab GBK 编码损坏修复
- validate_contracts.py setattr 字段名修正
- memory_service.c pthread_create → agentos_thread 迁移
- clustering.c const 指针释放移除
- tiktoken 依赖声明补全
- jest-config 归类 deps → devDeps
- 测试路径修正（run_tests.py）

### 工程规范建设

- Desktop 测试覆盖率 8% → 43.32%（537 测试全部通过）
- Desktop console.log 零化（67 处 → 0，迁移至 logger.ts）
- Desktop 硬编码 API URLs → 环境变量（.env.example）
- Desktop ESLint / TypeScript 全量修复（零警告零错误）
- Desktop CI || true 移除（4 处）
- 测试覆盖率目标：TS ≥ 40% ✅ (43.32%)
- AgentOS error_push_ex 覆盖 ≥ 100：全项目 409 处 ✅

### Known Issues

- 记忆系统定位为"有限记忆系统"（Finite Memory System）
- L3 Unbinder、L4 DBSCAN/HDBSCAN 聚类推迟至 v0.2.0
- 完整"无限记忆"(λ-Persistence) 推迟至 v0.2.0
- 测试文件中仍有 printf/free 调用（非生产代码）
- Commons 基础设施层（logging/memory）使用 fprintf（循环依赖）

### Breaking Changes

- 版本号从 v0.0.5 升级至 v0.1.0
- API 端点从硬编码改为环境变量（VITE_AGENTOS_GATEWAY_HOST/PORT）
- AGENTOS_COMPLIANCE_STRICT 模式默认 ON
- BUILD_TESTS 默认 ON

### v0.2.0 路线图

- MemoryRovol L3 Unbinder 完整实现
- MemoryRovol L4 HDBSCAN 聚类集成
- 自适应分块 + 向量化 (128k Chunking)
- 完整的热/温/冷记忆交换协议
- Desktop MemoryEvolution、SkillRegistry 等 P2 页面
- C 测试覆盖率 ≥ 50%
- seccomp 安全配置