# Airymax

OpenAirymax 开源极境
> AI Agent Runtime Platform Engineering

开源极境是一个专注于**智能体运行底座工程化平台**的开源组织。

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
│   └── agentrt/{atoms,commons,cupolas,daemons,gateway,heapstore,protocols}/  # 7 叶子仓
├── sdk/                          # 管理仓（多语言 SDK）
│   └── {sdk-python,sdk-go,sdk-rust,sdk-typescript,sdk-cli,sdk-tui}/  # 6 叶子仓
├── ecosystem/                    # 管理仓（工程生态系统）
│   └── {manager,prompts,examples,openlab,skills}/  # 5 叶子仓
├── products/                     # 管理仓（面向用户制品）
│   └── {desktop,docker,memoryrovol}/  # 3 叶子仓
├── devtools/                     # 顶层仓（开发工具）
├── docs/                         # 顶层仓（项目文档）
└── docs-closed/                  # 顶层仓（项目管理文档，闭源）
```

## 仓库组织

OpenAirymax 采用 **29 仓拆分方案**（v4.0）：

- **1 个伞仓**：`airymaxhub`（本仓库）
- **4 个管理仓**：`agentrt`、`sdk`、`ecosystem`、`products`（各自管理叶子仓 submodule）
- **21 个叶子仓**：分布在 4 个管理仓下
- **3 个顶层仓**：`devtools`、`docs`、`docs-closed`

除 `memoryrovol` 归属 `spharx` 组织外，其余 28 个仓库均归属 `openairymax` 组织（atomgit.com 平台）。

## 构建

```bash
# 源树外构建（BAN-33）
cmake -S agentrt -B ../build -DCMAKE_BUILD_TYPE=Release -DAGENTRT_WITH_MEMORYROVOL=ON
cmake --build ../build -j4
cd ../build && ctest --output-on-failure -j4
```

## 大文件说明

本项目历史上的 14MB GIF 动画文件已在 commit `ab49c6b` 中删除，不再纳入版本控制。

如需获取该动画文件，请通过以下方式：
- 联系项目维护者获取
- 或参考 `docs/` 目录下的静态截图替代

## 许可证

- 开源: AGPL-3.0-or-later OR Apache-2.0
- Copyright (C) SPHARX Ltd. All Rights Reserved.

## 分支策略

- **伞仓和 4 个管理仓**：仅保留 `main` 分支
- **21 个叶子仓**：保留 `feature/official-hubs-01` 分支
- **`agentrt` 管理仓**：分支保持不变（继承原 AgentRT 历史）
