# 仓库结构与子模块文档（REPOSITORIES.md）

> 本文件是 OpenAirymax 全部 38 个 git 仓库的权威索引，记录 `.gitmodules` 层次、URL 约定与分支策略。
> 最后更新：2026-08-30（0.1.6 生态 SSoT S-7：叶子仓分支与 .gitmodules/实际分支对齐为 develop/hubs-01）· 维护者：SPHARX Ltd.

---

## 1. 总览

OpenAirymax 采用 **伞仓 + 双工程大管理仓 + 管理仓 + 叶子仓 + 顶层仓** 结构：

| 层级 | 数量 | 说明 |
|------|------|------|
| 伞仓（umbrella） | 1 | `airymaxhub`，聚合 6 个管理仓 |
| 大管理仓（super-management） | 2 | `agent-workload`（用户态工程，v0.1.4 由 agent-runtim 改名）/ `agent-linux`（内核态工程，原 agentrt-linux），各自通过 `.gitmodules` 管理其下管理仓/叶子仓 |
| 管理仓（management） | 4 | `agentrt` / `sdk` / `ecosystem` / `products`，位于 agent-workload 下，各自通过 `.gitmodules` 管理叶子仓 |
| 叶子仓（leaf） | 29 | 分布在 4 个管理仓下（7 + 6 + 6 + 3）与 agent-linux 下（8） |
| 顶层仓（top-level） | 4 | `tools`（v0.1.4 由 devtools 改名）/ `docs` / `closed-docs` / `closed-dev-build`，直属伞仓 |
| **合计** | **38** | — |

> **双工程结构（v0.1.3 决策，v0.1.4 更名）**：区分用户态工程与内核态工程——
> - **agent-workload**（用户态）：agentrt（核心运行时）+ ecosystem（生态）+ products（产品）+ sdk（开发者 SDK）
> - **agent-linux**（内核态）：AirymaxOS 智能体操作系统（kernel + services + system + cloudnative 等 8 叶子仓）
> 两者构建层面零互相引用，通过 IRON-9 共享契约层（[SC] 字节级一致）与语义同源层（[SS]）协作。

## 2. 层次结构图

```
airymaxhub/                                     # 伞仓（git@atomgit.com:openairymax/airymaxhub.git, main）
│
├── agent-workload/ [大管理仓] → agent-workload.git  # 用户态工程（v0.1.3 起，v0.1.4 由 agent-runtim 改名）
│   ├── agentrt/      [管理仓] → agentos.git（历史保留 URL，见 §4 E1）
│   │   ├── atoms/       [叶子仓]                  # A 类微核心原语（corekern/syscall/memory/taskflow）
│   │   ├── commons/     [叶子仓]
│   │   ├── cupolas/     [叶子仓]                  # 安全框架
│   │   ├── daemons/     [叶子仓]
│   │   ├── gateway/     [叶子仓]
│   │   ├── heapstore/   [叶子仓]                  # 内存引擎
│   │   ├── protocols/   [叶子仓]
│   │   ├── cmake/       [直属目录]                # 构建系统模块（v0.1.2 起自伞仓迁入，IRON-9 [IND] 独立层）
│   │   ├── scripts/     [直属目录]                # 官方安装器 install.sh/install.ps1（v0.1.2 起自伞仓迁入）
│   │   └── LICENSES/    [直属目录]                # SPDX 许可文本
│   ├── ecosystem/      [管理仓] → ecosystem.git
│   │   └── manager/ · prompts/ · markets/ · skills/ · agents/  [叶子仓 ×5]
│   ├── products/       [管理仓] → products.git
│   │   └── desktop/ · docker/ · memoryrovol/      [叶子仓 ×3]
│   └── sdk/            [管理仓] → sdk.git
│       └── sdk-python/ · sdk-go/ · sdk-rust/ · sdk-typescript/ · cli/ · tui/  [叶子仓 ×6]
│
├── agent-linux/     [大管理仓] → agent-linux.git   # 内核态工程（原 agentrt-linux，v0.1.3 改名）
│   ├── kernel/              [叶子仓]               # Linux 6.6 + sched_tac + eBPF + io_uring + Rust
│   ├── memory/              [叶子仓]               # MemoryRovol 内核态 + CXL + PMEM + MGLRU 多代 LRU
│   ├── security/            [叶子仓]               # capability(seL4) + LSM + Landlock + 国密
│   ├── cognition/           [叶子仓]               # CoreLoopThree kthread + LLM 调度 + Token 能效
│   ├── services/            [叶子仓]               # VFS + 网络 + 12 daemons + io_uring 消息传递
│   ├── system/              [叶子仓]               # RPM + dnf + 配置 + shell + DevStation
│   ├── cloudnative/         [叶子仓]               # K8s CRD + containerd shim + OCI + CNI
│   └── tests-linux/     [叶子仓]               # 单元 + 集成 + 形式化验证(seL4) + Soak + Chaos
│
├── docs/            [顶层仓] → docs.git
├── tools/           [顶层仓] → tools.git           # 开发工具（v0.1.4 由 devtools 改名）
├── closed-docs/     [顶层仓] → closed-docs.git
└── closed-dev-build/ [顶层仓] → closed-dev-build.git
```

> **伞仓直属目录说明**：伞仓根不含直属源码目录（v0.1.3 起仅收编 6 个管理仓子模块）。
> 构建系统模块（`cmake/`）与官方安装器（`scripts/`）自 v0.1.2 起迁入
> agentrt 管理仓——构建系统与安装器属 IRON-9 [IND] 完全独立层，用户态
> （agent-workload）与内核态（agent-linux）各自独立。

## 3. `.gitmodules` 文件清单

全工程共 **7 个 `.gitmodules` 文件**，分别位于伞仓、2 个大管理仓与 4 个管理仓根目录：

| # | 文件路径 | 子模块数 | 子模块类型 | 说明 |
|---|----------|----------|------------|------|
| 1 | `airymaxhub/.gitmodules` | 6 | 大管理仓 + 顶层仓 | agent-workload, agent-linux, docs, closed-docs, tools, closed-dev-build |
| 2 | `agent-workload/.gitmodules` | 4 | 管理仓 | agentrt, ecosystem, products, sdk |
| 3 | `agent-workload/agentrt/.gitmodules` | 7 | 叶子仓 | atoms, commons, cupolas, daemons, gateway, heapstore, protocols |
| 4 | `agent-linux/.gitmodules` | 8 | 叶子仓 | kernel, memory, security, cognition, services, system, cloudnative, tests-linux |
| 5 | `agent-workload/sdk/.gitmodules` | 6 | 叶子仓 | sdk-python, sdk-go, sdk-rust, sdk-typescript, cli, tui |
| 6 | `agent-workload/ecosystem/.gitmodules` | 5 | 叶子仓 | manager, prompts, markets, skills, agents |
| 7 | `agent-workload/products/.gitmodules` | 3 | 叶子仓 | desktop, docker, memoryrovol |

> 顶层仓（tools / docs / closed-docs / closed-dev-build）为单仓，不含 `.gitmodules`。

## 4. URL 约定

### 标准格式

```
git@atomgit.com:openairymax/<仓库名>.git
```

### 例外清单

| 编号 | 仓库名 | 实际 URL | 原因 |
|------|--------|----------|------|
| **E1** | `agentrt`（管理仓） | `git@atomgit.com:openairymax/agentos.git` | 历史保留：agentrt 管理仓的 git 远端名沿用改名前的 `agentos.git`，用户决策保持不变（内部代码前缀 `agentos_→agentrt_→airy_` 已完成两阶段改名，但 git remote 名保留） |
| **E2** | `cli` / `tui`（sdk 叶子仓） | `git@atomgit.com:openairymax/cli.git` / `tui.git` | 命名约定：cli 与 tui 作为用户直接交互的独立工具，URL 不带 `sdk-` 前缀（区别于 sdk-python / sdk-go / sdk-rust / sdk-typescript 等语言绑定 SDK） |
| **E3** | `memoryrovol`（products 叶子仓） | `git@atomgit.com:spharx/memoryrovol.git` | 组织归属：memoryrovol 归属 `spharx` 个人组织而非 `openairymax` 组织（商业隔离层，B 类语义） |
| **E4** | `agent-linux`（大管理仓） | `git@atomgit.com:openairymax/agent-linux.git` | v0.1.3 由 `agentrt-linux` 改名；本地目录/引用与远程仓均已同步 |
| **E5** | `agent-workload`（大管理仓） | `git@atomgit.com:openairymax/agent-workload.git` | v0.1.4 由 `agent-runtim` 改名；本地目录/引用与远程仓均已同步 |
| **E6** | `tools`（顶层仓） | `git@atomgit.com:openairymax/tools.git` | v0.1.4 由 `devtools` 改名；本地目录/引用与远程仓均已同步 |

### 完整仓库 URL 表

| 仓库 | 类型 | URL | 分支 |
|------|------|-----|------|
| airymaxhub | 伞仓 | `git@atomgit.com:openairymax/airymaxhub.git` | `main` |
| agent-workload | 大管理仓 | `git@atomgit.com:openairymax/agent-workload.git` ⚠️E5 | `main` |
| agent-linux | 大管理仓 | `git@atomgit.com:openairymax/agent-linux.git` ⚠️E4 | `main` |
| agentrt | 管理仓 | `git@atomgit.com:openairymax/agentos.git` ⚠️E1 | `main` |
| sdk | 管理仓 | `git@atomgit.com:openairymax/sdk.git` | `main` |
| ecosystem | 管理仓 | `git@atomgit.com:openairymax/ecosystem.git` | `main` |
| products | 管理仓 | `git@atomgit.com:openairymax/products.git` | `main` |
| tools | 顶层仓 | `git@atomgit.com:openairymax/tools.git` ⚠️E6 | `main` |
| docs | 顶层仓 | `git@atomgit.com:openairymax/docs.git` | `main` |
| closed-docs | 顶层仓 | `git@atomgit.com:openairymax/closed-docs.git` | `main` |
| closed-dev-build | 顶层仓 | `git@atomgit.com:openairymax/closed-dev-build.git` | `main` |
| atoms | 叶子仓 | `git@atomgit.com:openairymax/atoms.git` | `develop/hubs-01` |
| commons | 叶子仓 | `git@atomgit.com:openairymax/commons.git` | `develop/hubs-01` |
| cupolas | 叶子仓 | `git@atomgit.com:openairymax/cupolas.git` | `develop/hubs-01` |
| daemons | 叶子仓 | `git@atomgit.com:openairymax/daemons.git` | `develop/hubs-01` |
| gateway | 叶子仓 | `git@atomgit.com:openairymax/gateway.git` | `develop/hubs-01` |
| heapstore | 叶子仓 | `git@atomgit.com:openairymax/heapstore.git` | `develop/hubs-01` |
| protocols | 叶子仓 | `git@atomgit.com:openairymax/protocols.git` | `develop/hubs-01` |
| kernel | 叶子仓 | `git@atomgit.com:openairymax/kernel.git` | `ALK-6.6-dev` |
| memory | 叶子仓 | `git@atomgit.com:openairymax/memory.git` | `develop/hubs-01` |
| security | 叶子仓 | `git@atomgit.com:openairymax/security.git` | `develop/hubs-01` |
| cognition | 叶子仓 | `git@atomgit.com:openairymax/cognition.git` | `develop/hubs-01` |
| services | 叶子仓 | `git@atomgit.com:openairymax/services.git` | `develop/hubs-01` |
| system | 叶子仓 | `git@atomgit.com:openairymax/system.git` | `develop/hubs-01` |
| cloudnative | 叶子仓 | `git@atomgit.com:openairymax/cloudnative.git` | `develop/hubs-01` |
| tests-linux | 叶子仓 | `git@atomgit.com:openairymax/tests-linux.git` | `develop/hubs-01` |
| sdk-python | 叶子仓 | `git@atomgit.com:openairymax/sdk-python.git` | `develop/hubs-01` |
| sdk-go | 叶子仓 | `git@atomgit.com:openairymax/sdk-go.git` | `develop/hubs-01` |
| sdk-rust | 叶子仓 | `git@atomgit.com:openairymax/sdk-rust.git` | `develop/hubs-01` |
| sdk-typescript | 叶子仓 | `git@atomgit.com:openairymax/sdk-typescript.git` | `develop/hubs-01` |
| cli | 叶子仓 | `git@atomgit.com:openairymax/cli.git` ⚠️E2 | `develop/hubs-01` |
| tui | 叶子仓 | `git@atomgit.com:openairymax/tui.git` ⚠️E2 | `develop/hubs-01` |
| manager | 叶子仓 | `git@atomgit.com:openairymax/manager.git` | `develop/hubs-01` |
| prompts | 叶子仓 | `git@atomgit.com:openairymax/prompts.git` | `develop/hubs-01` |
| markets | 叶子仓 | `git@atomgit.com:openairymax/markets.git` | `develop/hubs-01` |
| skills | 叶子仓 | `git@atomgit.com:openairymax/skills.git` | `develop/hubs-01` |
| agents | 叶子仓 | `git@atomgit.com:openairymax/agents.git` | `main` |
| desktop | 叶子仓 | `git@atomgit.com:openairymax/desktop.git` | `develop/hubs-01` |
| docker | 叶子仓 | `git@atomgit.com:openairymax/docker.git` | `develop/hubs-01` |
| memoryrovol | 叶子仓 | `git@atomgit.com:spharx/memoryrovol.git` ⚠️E3 | `develop/hubs-01` |

## 5. 分支策略

| 仓库类型 | 默认分支 | 说明 |
|----------|----------|------|
| 伞仓 | `main` | `airymaxhub` |
| 大管理仓 | `main` | agent-workload / agent-linux |
| 管理仓 | `main` | agentrt / sdk / ecosystem / products |
| 顶层仓 | `main` | tools / docs / closed-docs / closed-dev-build |
| 叶子仓 | `develop/hubs-01` | 全部 29 个叶子仓统一使用此分支（agents 例外：`main`；kernel 例外：`ALK-6.6-dev`） |

> 在 `.gitmodules` 中，每个子模块均显式声明 `branch = ` 字段，确保 `git submodule update --remote` 行为可预期。

## 6. 嵌套子模块的 git 存储布局

伞仓采用 gitfile + absorbed gitdir 方案，所有子模块的 git 数据集中存储于 `<工作区根>/.git/modules/OpenAirymax/modules/` 下（扁平存放，与子模块同名）：

```
<工作区根>/.git/modules/OpenAirymax/                 # 伞仓 git 数据（OpenAirymax 本身是上层工作区的 submodule）
└── modules/                                          # 全部子模块 git 数据扁平存放（gitfile 指向此处）
    ├── agent-workload/                               # 用户态大管理仓 git 数据
    ├── agent-linux/                                  # 内核态大管理仓 git 数据
    ├── agentrt/ ... sdk/ ... ecosystem/ ... products/  # 4 个管理仓 git 数据
    ├── tools/ ... docs/ ... closed-docs/ ... closed-dev-build/  # 顶层仓 git 数据
    └── ...
```

每个子模块路径下的 `.git` 是一个 **gitfile**（非目录），内容形如：

```
# 叶子仓 gitfile 示例（agent-workload/agentrt/atoms/.git）
gitdir: <工作区根>/.git/modules/OpenAirymax/modules/atoms
```

> v0.1.3 移动管理仓 / v0.1.4 更名后，模块存储目录已与子模块同名（agent-workload / agent-linux / tools / closed-docs），gitfile 相对路径指向扁平 modules 区，跨工作区移动不受相对深度影响。

## 7. 常用操作

### 7.1 全量克隆（含所有嵌套子模块）

```bash
git clone --recursive git@atomgit.com:openairymax/airymaxhub.git OpenAirymax
cd OpenAirymax
```

### 7.2 已克隆后初始化子模块

```bash
cd OpenAirymax
git submodule update --init --recursive
```

### 7.3 拉取所有子模块最新提交

```bash
# 按各 .gitmodules 中声明的 branch 拉取
git submodule update --remote --recursive
```

### 7.4 新增叶子仓到管理仓

以给 `agent-linux` 新增一个叶子仓 `foo` 为例：

```bash
cd agent-linux
# 1. 在远端创建 git@atomgit.com:openairymax/foo.git（develop/hubs-01 分支）
# 2. 添加为子模块
git submodule add -b develop/hubs-01 git@atomgit.com:openairymax/foo.git foo
# 3. 提交
git commit -am "feat: 新增 foo 叶子仓"
git push
# 4. 回到伞仓，更新 agent-linux 子模块指针
cd ..
git add agent-linux
git commit -m "chore: 更新 agent-linux 子模块指针（新增 foo）"
git push
```

### 7.5 修改叶子仓后同步指针

```bash
# 在叶子仓内提交并推送
cd agent-linux/kernel
git add . && git commit -m "fix: ..." && git push
# 回到大管理仓提交指针更新
cd ..
git add kernel
git commit -m "chore: 更新 kernel 子模块指针"
git push
# 回到伞仓提交大管理仓指针更新
cd ..
git add agent-linux
git commit -m "chore: 更新 agent-linux 子模块指针"
git push
```

## 8. 变更历史

| 日期 | 变更 | 提交 |
|------|------|------|
| 2026-07-07 | 建立 agentrt-linux 管理仓为伞仓直属 submodule，注册 8 个叶子仓；agentrt URL 保持 agentos.git 不变；cli/tui 确认无 sdk- 前缀 | `dccc013`（伞仓）/ `d5c579f`（agentrt-linux） |
| 2026-08-23 | **v0.1.3 双工程结构**：新增 agent-runtim 用户态大管理仓（收编 agentrt/ecosystem/products/sdk）；agentrt-linux 改名 agent-linux；伞仓仅收编 6 个管理仓；根目录 cmake/scripts 已随 v0.1.2 迁入 agentrt | `a2b0b36`（agent-runtim）/ 伞仓提交见 git log |
| 2026-08-23 | **v0.1.4 更名**：用户态大管理仓 agent-runtim → **agent-workload**；顶层仓 devtools → **tools**；本地目录、gitlink、模块存储目录、`.gitmodules` / `.git/config` 与全部引用已同步；远程仓已由维护者完成改名 | agent-workload / tools / 伞仓提交见 git log |

---

SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0
Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
