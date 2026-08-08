## 组织介绍

OpenAirymax 开源极境，是一个专注于智能体工程的开源组织。

## 项目介绍

OpenAirymax 开放两个同源但不同层级的项目：

- AirymaxRT「极境智能体运行平台工程」是一个跨平台（Linux、Windows、MacOS）的 Agent 运行底座，面向普通用户和普通开发者，为其提供稳定的工业级智能体运行底座。
- AirymaxOS「极境智能体操作系统」是一个基于 Linux 6.6 / 7.1 的智能体操作系统，专为 Agent 负载设计，提供优化的性能和稳定性，面向开源社区和专业开发者，构建稳定的下一代智能体原生操作系统。    

> RT用户态和OS内核态架构相同，工程标准规范相同，可组合，则是 Airymax 的完全体，两个产品也可以独立运行。

## 项目结构

airymaxhub 伞仓：

- user mode：agentrt 「AirymaxRT 智能体运行底座」主仓
- kernel mode：agentrt-linux 「AirymaxOS 智能体操作系统」主仓

> OpenAirymax 采用多仓层级组织,完整的子模块结构、URL 约定与分支策略详见 [REPOSITORIES.md](REPOSITORIES.md)。

## 许可证

本项目采用 **AGPL v3 + Apache 2.0** 双许可证，各叶子仓根目录均有各自的 LICENSE 文件。

> 为什么叫极境？项目的发起人之一 Liren_Wang 认为，它为 Agent 提供了原生基础的运行环境，利用特殊的工程设计，可以让使用的不是最先进 LLM 的 Agent 在这套系统加持下，将能力**极尽升华** Ultimate Sublimation 到一个新的境界，实现更高级的功能和性能，达到“越级战斗”的效果。

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
