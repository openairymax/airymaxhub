# agentrt-sel4 — seL4 微内核研究项目

> **模块路径**: `agentrt-sel4/` | **版本**: 0.1.1（文档占位） | **状态**: 研究阶段

## 概述

`agentrt-sel4/` 是 Airymax 平台在 seL4 微内核方向的研究项目，探索将 Airymax 智能体运行时平台的核心理念（MicroCoreRT / AgentsIPC / Cupolas / MemoryRovol / CoreLoopThree）映射到 seL4 微内核上的可行性。

seL4 是世界上第一个经过形式化验证的微内核，其 capability-based security model 和 minimality principle 与 Airymax 的微内核设计思想高度一致。本项目作为 AirymaxOS（agentrt-linux）的并行研究线，探索在 seL4 上构建智能体操作系统的可能性。

### 与 AirymaxOS 的关系

| 维度 | AirymaxOS（agentrt-linux） | agentrt-sel4 |
|------|---------------------------|-------------|
| **内核基线** | Linux 6.6 | seL4 微内核 |
| **验证级别** | 工程验证 | 形式化验证 |
| **成熟度** | 1.0.1 开发中 | 0.1.1 研究阶段 |
| **设计支柱** | 微内核思想 + Linux 生态 + Airymax 同源 | 微内核实现 + 形式化验证 + Airymax 同源 |

## 当前状态

- **版本**: 0.1.1 — 文档占位，无代码实施
- **优先级**: P2（研究阶段，0.1.1 不开发具体代码）
- **依赖**: 无（独立研究项目）

## 研究目标（1.0.1+）

- seL4 上 Airymax 核心原语的 capability 映射
- AgentsIPC 协议在 seL4 endpoint 上的实现
- Cupolas 安全穹顶与 seL4 capability system 的融合
- MemoryRovol 记忆卷载在 seL4 上的持久化方案

## 许可证

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.

双许可证：**AGPL-3.0-or-later OR Apache-2.0**（SPDX: `AGPL-3.0-or-later OR Apache-2.0`）。

---

> **文档结束** | 0.1.1 P2 占位，seL4 微内核研究项目