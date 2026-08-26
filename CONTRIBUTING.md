# 贡献指南 (Contributing Guide)

**最后更新**: 2026-08-04

欢迎来到 Airymax 社区！本仓库（`airymaxhub`）是聚合伞仓（umbrella repository），
通过 git submodule 聚合以下大管理仓（super-repo）：

- **用户态**：`agent-workload`（v0.1.4 由 `agent-runtim` 改名；含 `agentrt` 核心运行时、`sdk`、`ecosystem`、`products`）
- **内核态**：`agent-linux`（v0.1.3 由 `agentrt-linux` 改名）
- 顶层仓：`docs`、`closed-docs`、`tools`（v0.1.4 由 `devtools` 改名）、`developbuild`（由 `devbuild-closed` 改名，含 `airymax-binary/` 离线包归档）

大部分开发工作发生在各个子仓库（leaf repository）中。请先阅读对应子仓库内的
`CONTRIBUTING.md`（如有）以获得该仓库的具体约定。

## 1. 贡献流程

1. 在对应子仓库创建分支（功能分支 `feature/*`、修复分支 `fix/*`、发布分支 `release/*`）。
2. 一个 commit 只包含一个逻辑变更，保持可 bisect。
3. 提交前确保本地测试通过（各子仓库的测试命令见其 CI workflow）。
4. 通过 Pull Request 合入 `main`（或子仓库声明的目标分支）。

## 2. 提交信息格式

遵循内核风格的提交信息：

```
<subsystem>: <summary>

<body: why > how > impact>
```

- 标题为祈使句、首字母大写、结尾无句号、建议 ≤72 字符；
- 正文解释 **why**（为什么变更）而非 what；
- 引用历史 commit 时使用 `hash ("subject")`，hash 前缀 ≥12 字符；
- 修复类提交必须包含 `Fixes:` 标签（不拆行）。

## 3. 署名要求（DCO）

每个提交必须包含 `Signed-off-by:`，表示你确认该贡献符合 Developer Certificate
of Origin 1.1（https://developercertificate.org/）。

## 4. 双许可与版权

对**开源核心层（L3）**（`agent-workload/` 下的 `agentrt/`、`sdk/`、`ecosystem/`、
`products/docker/`、`products/desktop/`、`agent-linux/` 非内核部分、`tools/`）的贡献，
将被视为以 **AGPL-3.0-or-later OR Apache-2.0** 双许可接受（SPDX: `AGPL-3.0-or-later
OR Apache-2.0`）。请在新增/修改的文件中保留 SPDX 头：

```
SPDX-FileCopyrightText: 2025-2026 SPHARX Ltd.
SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0
```

## 5. 特殊子仓库

- **`agent-linux/kernel/`**（L4）：必须使用 `GPL-2.0-only` 以保持与上游 Linux
  内核的许可兼容性。
- **`products/memoryrovol/`**（L5）：闭源商业产品，受 SPHARX 商业 EULA 约束，
  不接受外部源码贡献。商业合作请联系 business@spharx.cn。
- **`docs/OpenStandards/`**（L1）：CC-BY-4.0。

## 6. 安全问题

发现安全漏洞请**不要**在公开渠道披露，按 [SECURITY.md](SECURITY.md) 的流程报告。

---

© 2025-2026 SPHARX Ltd. 保留所有权利。
