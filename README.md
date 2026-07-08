# Airymax 极境  

> AI Agent Runtime Platform Engineering  

OpenAirymax 开源极境，是一个专注于**智能体工程**的开源组织，开源极境开放两个项目：  

- Airymax AgentRT 极境智能体运行底座平台工程  
- Airymax AgentOS 极境智能体操作系统  

## 项目结构

```
airymaxhub/                       # 伞仓（本仓库）
├── cmake/                        # 伞仓直属 CMake 模块
├── agentrt/                      # 管理仓（AirymaxRT核心运行底座）
├── sdk/                          # 管理仓（多语言 SDK）
├── ecosystem/                    # 管理仓（工程生态系统）
├── products/                     # 管理仓（面向用户制品）
├── agentrt-linux/                # 管理仓（AirymaxOS智能体操作系统）
├── devtools/                     # 顶层仓（开发工具与配置中心）
├── docs/                         # 顶层仓（开放文档中心）
└── other/                        # 顶层仓（其他闭源项目）
```

## 仓库组织

OpenAirymax 采用 **38 仓拆分方案**：

- **1 个伞仓**：`airymaxhub`（本仓库）
- **5 个管理仓**：`agentrt`、`sdk`、`ecosystem`、`products`、`agentrt-linux`（各自管理叶子仓 submodule）
- **29 个叶子仓**：分布在 5 个管理仓下（agentrt 7 + sdk 6 + ecosystem 5 + products 3 + agentrt-linux 8）
- **3 个顶层仓**：`devtools`、`docs`、`其他闭源`

除 `memoryrovol` 归属 `spharx` 组织外，其余 37 个仓库均归属 `openairymax` 组织。

> 完整的子模块结构、URL 约定与分支策略详见 [REPOSITORIES.md](REPOSITORIES.md)。

## 许可证

- 开源: AGPL-3.0-or-later OR Apache-2.0
- Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.

SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0

详见 [LICENSE](LICENSE) 和 [NOTICE](NOTICE)。
