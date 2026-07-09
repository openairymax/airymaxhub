# 仓库结构与子模块文档（REPOSITORIES.md）

> 本文件是 OpenAirymax 全部 38 个 git 仓库的权威索引，记录 `.gitmodules` 层次、URL 约定与分支策略。
> 最后更新：2026-07-07 · 维护者：SPHARX Ltd.

---

## 1. 总览

OpenAirymax 采用 **四层 38 仓拆分方案**：

| 层级 | 数量 | 说明 |
|------|------|------|
| 伞仓（umbrella） | 1 | `airymaxhub`，聚合所有管理仓与顶层仓 |
| 管理仓（management） | 5 | `agentrt` / `sdk` / `ecosystem` / `products` / `agentrt-linux`，各自通过 `.gitmodules` 管理叶子仓 |
| 叶子仓（leaf） | 29 | 分布在 5 个管理仓下（7 + 6 + 5 + 3 + 8） |
| 顶层仓（top-level） | 3 | `devtools` / `docs` / `docs-closed`，直属伞仓 |
| **合计** | **38** | — |

## 2. 层次结构图

```
airymaxhub/                                   # 伞仓（git@atomgit.com:openairymax/airymaxhub.git, main）
│
├── agentrt/         [管理仓] → agentos.git    # 历史保留 URL（见 §4 约定 E1）
│   ├── atoms/       [叶子仓]                  # A 类微核心原语（corekern/syscall/memory/taskflow）
│   ├── commons/     [叶子仓]
│   ├── cupolas/     [叶子仓]                  # 安全框架
│   ├── daemons/     [叶子仓]
│   ├── gateway/     [叶子仓]
│   ├── heapstore/   [叶子仓]                  # 内存引擎
│   └── protocols/   [叶子仓]
│
├── agentrt-linux/   [管理仓] → agentrt-linux.git   # AirymaxOS 智能体操作系统（与 agentrt 同级）
│   ├── kernel/              [叶子仓]                # Linux 6.6 + sched_ext + eBPF + io_uring + Rust
│   ├── memory/              [叶子仓]                # MemoryRovol 内核态 + CXL + PMEM + MGLRU 多代 LRU
│   ├── security/            [叶子仓]                # capability(seL4) + LSM + Landlock + 国密
│   ├── cognition/           [叶子仓]                # CoreLoopThree kthread + LLM 调度 + Token 能效
│   ├── services/            [叶子仓]                # VFS + 网络 + 12 daemons + io_uring 消息传递
│   ├── system/              [叶子仓]                # RPM + dnf + 配置 + shell + DevStation
│   ├── cloudnative/         [叶子仓]                # K8s CRD + containerd shim + OCI + CNI
│   └── tests-linux/     [叶子仓]                # 单元 + 集成 + 形式化验证(seL4) + Soak + Chaos
│
├── sdk/             [管理仓] → sdk.git
│   ├── sdk-python/     [叶子仓]
│   ├── sdk-go/         [叶子仓]
│   ├── sdk-rust/       [叶子仓]
│   ├── sdk-typescript/  [叶子仓]
│   ├── cli/            [叶子仓]                  # URL 不带 sdk- 前缀（见 §4 约定 E2）
│   └── tui/            [叶子仓]                  # URL 不带 sdk- 前缀（见 §4 约定 E2）
│
├── ecosystem/       [管理仓] → ecosystem.git
│   ├── manager/        [叶子仓]
│   ├── prompts/        [叶子仓]
│   ├── examples/       [叶子仓]
│   ├── openlab/        [叶子仓]
│   └── skills/         [叶子仓]
│
├── products/        [管理仓] → products.git
│   ├── desktop/        [叶子仓]
│   ├── docker/         [叶子仓]
│   └── memoryrovol/    [叶子仓]                  # 归属 spharx 组织（见 §4 约定 E3）
│
├── devtools/        [顶层仓] → devtools.git
├── docs/            [顶层仓] → docs.git
└── docs-closed/     [顶层仓] → docs-closed.git
```

## 3. `.gitmodules` 文件清单

全工程共 **6 个 `.gitmodules` 文件**，分别位于伞仓与 5 个管理仓根目录：

| # | 文件路径 | 子模块数 | 子模块类型 | 说明 |
|---|----------|----------|------------|------|
| 1 | `airymaxhub/.gitmodules` | 8 | 管理仓 + 顶层仓 | agentrt, agentrt-linux, sdk, ecosystem, products, docs, docs-closed, devtools |
| 2 | `airymaxhub/agentrt/.gitmodules` | 7 | 叶子仓 | atoms, commons, cupolas, daemons, gateway, heapstore, protocols |
| 3 | `airymaxhub/agentrt-linux/.gitmodules` | 8 | 叶子仓 | kernel, memory, security, cognition, services, system, cloudnative, tests-linux |
| 4 | `airymaxhub/sdk/.gitmodules` | 6 | 叶子仓 | sdk-python, sdk-go, sdk-rust, sdk-typescript, cli, tui |
| 5 | `airymaxhub/ecosystem/.gitmodules` | 5 | 叶子仓 | manager, prompts, examples, openlab, skills |
| 6 | `airymaxhub/products/.gitmodules` | 3 | 叶子仓 | desktop, docker, memoryrovol |

> 顶层仓（devtools / docs / docs-closed）为单仓，不含 `.gitmodules`。

## 4. URL 约定

### 标准格式

```
git@atomgit.com:openairymax/<仓库名>.git
```

### 例外清单

| 编号 | 仓库名 | 实际 URL | 原因 |
|------|--------|----------|------|
| **E1** | `agentrt`（管理仓） | `git@atomgit.com:openairymax/agentos.git` | 历史保留：agentrt 管理仓的 git 远端名沿用改名前的 `agentos.git`，用户决策保持不变（内部代码前缀 `agentos_→agentrt_` 已改名，但 git remote 名保留） |
| **E2** | `cli` / `tui`（sdk 叶子仓） | `git@atomgit.com:openairymax/cli.git` / `tui.git` | 命名约定：cli 与 tui 作为用户直接交互的独立工具，URL 不带 `sdk-` 前缀（区别于 sdk-python / sdk-go / sdk-rust / sdk-typescript 等语言绑定 SDK） |
| **E3** | `memoryrovol`（products 叶子仓） | `git@atomgit.com:spharx/memoryrovol.git` | 组织归属：memoryrovol 归属 `spharx` 个人组织而非 `openairymax` 组织（商业隔离层，B 类语义） |

### 完整仓库 URL 表

| 仓库 | 类型 | URL | 分支 |
|------|------|-----|------|
| airymaxhub | 伞仓 | `git@atomgit.com:openairymax/airymaxhub.git` | `main` |
| agentrt | 管理仓 | `git@atomgit.com:openairymax/agentos.git` ⚠️E1 | `main` |
| agentrt-linux | 管理仓 | `git@atomgit.com:openairymax/agentrt-linux.git` | `main` |
| sdk | 管理仓 | `git@atomgit.com:openairymax/sdk.git` | `main` |
| ecosystem | 管理仓 | `git@atomgit.com:openairymax/ecosystem.git` | `main` |
| products | 管理仓 | `git@atomgit.com:openairymax/products.git` | `main` |
| devtools | 顶层仓 | `git@atomgit.com:openairymax/devtools.git` | `main` |
| docs | 顶层仓 | `git@atomgit.com:openairymax/docs.git` | `main` |
| docs-closed | 顶层仓 | `git@atomgit.com:openairymax/docs-closed.git` | `main` |
| atoms | 叶子仓 | `git@atomgit.com:openairymax/atoms.git` | `feature/official-hubs-01` |
| commons | 叶子仓 | `git@atomgit.com:openairymax/commons.git` | `feature/official-hubs-01` |
| cupolas | 叶子仓 | `git@atomgit.com:openairymax/cupolas.git` | `feature/official-hubs-01` |
| daemons | 叶子仓 | `git@atomgit.com:openairymax/daemons.git` | `feature/official-hubs-01` |
| gateway | 叶子仓 | `git@atomgit.com:openairymax/gateway.git` | `feature/official-hubs-01` |
| heapstore | 叶子仓 | `git@atomgit.com:openairymax/heapstore.git` | `feature/official-hubs-01` |
| protocols | 叶子仓 | `git@atomgit.com:openairymax/protocols.git` | `feature/official-hubs-01` |
| kernel | 叶子仓 | `git@atomgit.com:openairymax/kernel.git` | `feature/official-hubs-01` |
| memory | 叶子仓 | `git@atomgit.com:openairymax/memory.git` | `feature/official-hubs-01` |
| security | 叶子仓 | `git@atomgit.com:openairymax/security.git` | `feature/official-hubs-01` |
| cognition | 叶子仓 | `git@atomgit.com:openairymax/cognition.git` | `feature/official-hubs-01` |
| services | 叶子仓 | `git@atomgit.com:openairymax/services.git` | `feature/official-hubs-01` |
| system | 叶子仓 | `git@atomgit.com:openairymax/system.git` | `feature/official-hubs-01` |
| cloudnative | 叶子仓 | `git@atomgit.com:openairymax/cloudnative.git` | `feature/official-hubs-01` |
| tests-linux | 叶子仓 | `git@atomgit.com:openairymax/tests-linux.git` | `feature/official-hubs-01` |
| sdk-python | 叶子仓 | `git@atomgit.com:openairymax/sdk-python.git` | `feature/official-hubs-01` |
| sdk-go | 叶子仓 | `git@atomgit.com:openairymax/sdk-go.git` | `feature/official-hubs-01` |
| sdk-rust | 叶子仓 | `git@atomgit.com:openairymax/sdk-rust.git` | `feature/official-hubs-01` |
| sdk-typescript | 叶子仓 | `git@atomgit.com:openairymax/sdk-typescript.git` | `feature/official-hubs-01` |
| cli | 叶子仓 | `git@atomgit.com:openairymax/cli.git` ⚠️E2 | `feature/official-hubs-01` |
| tui | 叶子仓 | `git@atomgit.com:openairymax/tui.git` ⚠️E2 | `feature/official-hubs-01` |
| manager | 叶子仓 | `git@atomgit.com:openairymax/manager.git` | `feature/official-hubs-01` |
| prompts | 叶子仓 | `git@atomgit.com:openairymax/prompts.git` | `feature/official-hubs-01` |
| examples | 叶子仓 | `git@atomgit.com:openairymax/examples.git` | `feature/official-hubs-01` |
| openlab | 叶子仓 | `git@atomgit.com:openairymax/openlab.git` | `feature/official-hubs-01` |
| skills | 叶子仓 | `git@atomgit.com:openairymax/skills.git` | `feature/official-hubs-01` |
| desktop | 叶子仓 | `git@atomgit.com:openairymax/desktop.git` | `feature/official-hubs-01` |
| docker | 叶子仓 | `git@atomgit.com:openairymax/docker.git` | `feature/official-hubs-01` |
| memoryrovol | 叶子仓 | `git@atomgit.com:spharx/memoryrovol.git` ⚠️E3 | `feature/official-hubs-01` |

## 5. 分支策略

| 仓库类型 | 默认分支 | 说明 |
|----------|----------|------|
| 伞仓 | `main` | `airymaxhub` |
| 管理仓 | `main` | agentrt / agentrt-linux / sdk / ecosystem / products |
| 顶层仓 | `main` | devtools / docs / docs-closed |
| 叶子仓 | `feature/official-hubs-01` | 全部 29 个叶子仓统一使用此分支 |

> 在 `.gitmodules` 中，每个子模块均显式声明 `branch = ` 字段，确保 `git submodule update --remote` 行为可预期。

## 6. 嵌套子模块的 git 存储布局

伞仓采用 gitfile + absorbed gitdir 方案，所有子模块的 git 数据集中存储于伞仓 `.git/modules/` 下：

```
SpharxWorks/.git/modules/OpenAirymax/                 # 伞仓 git 数据（OpenAirymax 本身是 SpharxWorks 的 submodule）
├── agentrt/                                          # agentrt 管理仓 git 数据
├── agentrt-linux/                                    # agentrt-linux 管理仓 git 数据
│   └── modules/                                      # agentrt-linux 的 8 个叶子仓 git 数据
│       ├── kernel/
│       ├── memory/
│       ├── security/
│       ├── cognition/
│       ├── services/
│       ├── system/
│       ├── cloudnative/
│       └── tests-linux/
├── sdk/                                              # sdk 管理仓 git 数据
│   └── modules/                                      # sdk 的 6 个叶子仓 git 数据
│       ├── sdk-python/ ... sdk-rust/ ... cli/ ... tui/
├── ecosystem/                                        # ecosystem 管理仓 git 数据
│   └── modules/                                      # ecosystem 的 5 个叶子仓 git 数据
├── products/                                         # products 管理仓 git 数据
│   └── modules/                                      # products 的 3 个叶子仓 git 数据
├── devtools/ ... docs/ ... docs-closed/               # 顶层仓 git 数据
└── ...
```

每个子模块路径下的 `.git` 是一个 **gitfile**（非目录），内容形如：

```
# 叶子仓 gitfile 示例（agentrt-linux/kernel/.git）
gitdir: ../../../.git/modules/OpenAirymax/modules/agentrt-linux/modules/kernel
```

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

以给 `agentrt-linux` 新增一个叶子仓 `foo` 为例：

```bash
cd agentrt-linux
# 1. 在远端创建 git@atomgit.com:openairymax/foo.git（feature/official-hubs-01 分支）
# 2. 添加为子模块
git submodule add -b feature/official-hubs-01 git@atomgit.com:openairymax/foo.git foo
# 3. 提交
git commit -am "feat: 新增 foo 叶子仓"
git push
# 4. 回到伞仓，更新 agentrt-linux 子模块指针
cd ..
git add agentrt-linux
git commit -m "chore: 更新 agentrt-linux 子模块指针（新增 foo）"
git push
```

### 7.5 修改叶子仓后同步指针

```bash
# 在叶子仓内提交并推送
cd agentrt-linux/kernel
git add . && git commit -m "fix: ..." && git push
# 回到管理仓提交指针更新
cd ..
git add kernel
git commit -m "chore: 更新 kernel 子模块指针"
git push
# 回到伞仓提交管理仓指针更新
cd ..
git add agentrt-linux
git commit -m "chore: 更新 agentrt-linux 子模块指针"
git push
```

## 8. 变更历史

| 日期 | 变更 | 提交 |
|------|------|------|
| 2026-07-07 | 建立 agentrt-linux 管理仓为伞仓直属 submodule，注册 8 个叶子仓；agentrt URL 保持 agentos.git 不变；cli/tui 确认无 sdk- 前缀 | `dccc013`（伞仓）/ `d5c579f`（agentrt-linux） |

---

SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0
Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
