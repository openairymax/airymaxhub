# Airymax 极境  

OpenAirymax 开源极境 - 操作系统化的智能体运行底座
> AI Agent Runtime Platform Engineering  

## 项目结构  

```
airymaxhub/
├── agentrt/         # 核心底座管理仓（继承原AgentOS&AgentRT历史）
├── sdk/             # SDK 管理仓
├── ecosystem/       # 生态管理仓
├── products/        # 产品管理仓
├── devtools/        # 开发工具仓
└── docs/            # 文档仓
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

## 许可证  

- 开源代码: AGPL-3.0-or-later OR Apache-2.0  

Copyright (C) 2025-2026 SPHARX Ltd. All Rights Reserved.
