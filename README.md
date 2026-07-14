# Airymax 极境  

> AI Agent Runtime Platform Engineering  

OpenAirymax 开源极境，是一个专注于**智能体工程**的开源组织，开源极境开放两个项目：  

- Airymax AgentRT 极境智能体运行底座平台工程  
- AirymaxOS 极境智能体操作系统  

## 项目结构

```
airymaxhub/           # 伞仓
├── cmake/            # 伞仓直属 CMake 模块
├── agentrt/          # 管理仓：AirymaxRT 核心运行底座
├── agentrt-linux/    # 管理仓：AirymaxOS 操作系统 Linux 发行版
├── sdk/              # 管理仓：多语言 SDK
├── ecosystem/        # 管理仓：工程生态系统
├── products/         # 管理仓：面向用户制品
├── devtools/         # 顶层仓：开发工具与配置中心
├── docs/             # 顶层仓：开放文档中心
└── docs-closed/      # 顶层仓：闭源管理文档
```

## 仓库组织  

OpenAirymax 采用 **多仓层级组织方案**：

- **伞仓 1 个**：`airymaxhub`（本仓库）
- **管理仓 5 个**：`agentrt`、`sdk`、`ecosystem`、`products`、`agentrt-linux`（各自管理叶子仓 submodule）
- **叶子仓 29 个**：分布在 5 个管理仓下（agentrt 7 + sdk 6 + ecosystem 5 + products 3 + agentrt-linux 8）
- **顶层仓 3 个**：`devtools`、`docs`、`docs-closed`

> 完整的子模块结构、URL 约定与分支策略详见 [REPOSITORIES.md](REPOSITORIES.md)。

## 许可证

本项目所有子仓采用 **AGPL v3 + Apache 2.0** 双许可证（SPDX: `AGPL-3.0-or-later OR Apache-2.0`），可任选其一使用。各叶子仓根目录均有 LICENSE 文件。

另外：为什么叫极境？项目的发起人之一Liren_Wang认为，这是一个为Agent创造的天阶功法，类似“天火三玄变”，它为Agent提供了原生基础的运行环境，能够让不是那么强的LLM在这套功法下，极尽升华到一个新的境界，可以跃级战斗，实现更高级的功能和性能。  

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
