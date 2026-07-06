# Airymax

OpenAirymax 开源极境
> AI Agent Runtime Platform Engineering

开源极境是一个专注于**智能体工程**的开源组织。开源极境开放两个项目：
- AirymaxAgentRT 极境智能体运行底座平台工程  
- AirymaxOS 极境智能体操作系统   

## 项目结构  

```
airymaxhub/                       # 伞仓（本仓库）
├── cmake/                        # 伞仓直属 CMake 模块（5 个 .cmake 文件，非 submodule）
│   ├── compilerflags.cmake       # 编译器标志配置
│   ├── dependencies.cmake        # 第三方依赖检测
│   ├── platform.cmake            # 平台/编译器检测
│   ├── sanitizers.cmake          # Sanitizer 配置
│   └── utils.cmake               # 统一构建打印系统
├── agentrt/                      # 管理仓（核心运行底座，继承原 AgentOS & AgentRT 历史）
│   └── {atoms,commons,cupolas,daemons,gateway,heapstore,protocols}/  # 7 叶子仓
├── sdk/                          # 管理仓（多语言 SDK）
│   └── {sdk-python,sdk-go,sdk-rust,sdk-typescript,cli,tui}/  # 6 叶子仓
├── ecosystem/                    # 管理仓（工程生态系统）
│   └── {manager,prompts,examples,openlab,skills}/  # 5 叶子仓
├── products/                     # 管理仓（面向用户制品）
│   └── {desktop,docker,memoryrovol}/  # 3 叶子仓
├── devtools/                     # 顶层仓（开发工具）
└── docs/                         # 顶层仓（项目管理文档）
```

## 仓库组织  

OpenAirymax 采用 **仓拆分方案**：

- **1 个伞仓**：`airymaxhub`（本仓库）
- **4 个管理仓**：`agentrt`、`sdk`、`ecosystem`、`products`（各自管理叶子仓 submodule）
- **21 个叶子仓**：分布在 4 个管理仓下
- **3 个顶层仓**：`devtools`、`docs`、其它闭源仓

除 `memoryrovol` 归属 `spharx` 组织外，其余 28 个仓库均归属 `openairymax` 组织。  

## 许可证  

- 开源: AGPL-3.0-or-later OR Apache-2.0  
- Copyright (C) SPHARX Ltd. All Rights Reserved.  
