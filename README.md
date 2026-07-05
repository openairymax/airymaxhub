# Airymax Hub

Airymax 伞仓库（airymaxhub）— AI Agent 运行时平台工程。

## 仓库结构

```
airymaxhub/
├── agentrt/          # AgentRT 管理仓（继承 AgentRT 历史，agentos.git）
├── sdk/              # SDK 管理仓（sdk.git，6 语言 SDK 子模块）
├── ecosystem/        # 生态管理仓（ecosystem.git，5 生态子模块）
├── products/         # 产品管理仓（products.git，3 产品子模块）
├── devtools/         # 开发工具仓（devtools.git，scripts/deploy/tests）
├── docs/             # 开放文档仓（docs.git）
└── docs-closed/      # 闭源文档仓（docs-closed.git）
```

## 子模块

| 子模块 | 仓库 | 说明 |
|--------|------|------|
| agentrt | agentos.git | AgentRT 管理仓（atoms/commons/cupolas/heapstore/protocols/gateway/daemons） |
| sdk | sdk.git | SDK 管理仓（sdk-python/sdk-go/sdk-rust/sdk-typescript/cli/tui） |
| ecosystem | ecosystem.git | 生态管理仓（manager/prompts/examples/openlab/skills） |
| products | products.git | 产品管理仓（desktop/docker/memoryrovol） |
| devtools | devtools.git | 开发工具（scripts/deploy/tests） |
| docs | docs.git | 开放文档 |
| docs-closed | docs-closed.git | 闭源文档 |

## 许可证

- 开源代码: AGPL-3.0-or-later OR Apache-2.0
- MemoryRovol: SPHARX Ltd. 商业 EULA v1.0

Copyright (C) 2025-2026 SPHARX Ltd. All Rights Reserved.
SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0
