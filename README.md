# OpenAirymax 开源极境

## 构建智能体操作系统的基石

OpenAirymax 是专注于 AI Agent 操作系统领域的开源组织，致力于为智能体工作负载构建服务端的操作系统基础设施。

## 组织使命

**见证 AI 的智能涌现**

OpenAirymax 旨在打造完整的 AI Agent 操作系统生态，从内核机制到应用平台，为多智能体协同、自主进化、内在安全提供全栈解决方案。

## 核心项目

| 项目 | 说明 |
|------|------|
| [AgentOS](AgentOS/) | 智能体操作系统 |

## 技术愿景

<div align="center">

**From data intelligence emerges**

</div>

OpenAirymax 的技术路线围绕以下核心理念展开：

- **群体智能**: 通过操作系统级机制实现多 Agent 高效协同
- **内在安全**: 沙箱隔离、权限仲裁、输入净化、审计追踪四重防护
- **认知循环**: 感知、规划、行动的三层认知架构
- **记忆分层**: L1 原始卷 → L2 特征层 → L3 结构层 → L4 模式层
- **自主进化**: 动态调整策略，持续优化执行效果

## 快速开始

### AgentOS 快速入门

```bash
# 1. 克隆仓库
git clone --recursive https://atomgit.com/openairymax/agentos.git
cd agentos

# 2. 安装依赖 (Ubuntu)
sudo apt install -y build-essential cmake gcc g++ libssl-dev libsqlite3-dev ninja-build

# 3. 构建内核
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel $(nproc)

# 4. 运行测试
ctest --output-on-failure
```

### Docker 快速部署

```bash
# 构建镜像
docker build -f scripts/deploy/docker/Dockerfile.kernel -t agentos:latest .

# 运行容器
docker run -d --name agentos -p 8080:8080 agentos:latest
```

## 文档索引

| 文档 | 核心内容 |
|------|---------|
| [AgentOS](https://atomgit.com/openairymax/agentos/-/blob/main/README.md) | 项目介绍、架构设计、快速开始 |
| [架构原则](https://atomgit.com/openairymax/agentos/-/blob/main/docs/ARCHITECTURAL_PRINCIPLES.md) | 五维正交系统、24 项核心原则 |
| [贡献指南](https://atomgit.com/openairymax/agentos/-/blob/main/CONTRIBUTING.md) | 参与贡献的流程与规范 |
| [安全策略](https://atomgit.com/openairymax/agentos/-/blob/main/SECURITY.md) | 安全报告与漏洞处理流程 |
| [行为准则](https://atomgit.com/openairymax/agentos/-/blob/main/CODE_OF_CONDUCT.md) | 社区行为规范 |

## 社区与参与

我们欢迎所有形式的贡献：

- **报告问题**: 提交 Issue 报告，帮助我们提升质量
- **分享想法**: 提出新特性建议，让项目更强大
- **完善文档**: 帮助更多人理解 OpenAirymax 项目
- **编写代码**: 提交 Merge Request，共同创造历史

详细的参与方式请参阅 [AgentOS 贡献指南](https://atomgit.com/openairymax/agentos/-/blob/main/CONTRIBUTING.md)。

## 许可证

OpenAirymax 组织下项目默认采用 **Apache License 2.0**，除非另有说明。

各项目的具体许可证请参阅对应项目的 LICENSE 文件。

## 主平台

- **AtomGit**: [https://atomgit.com/openairymax/agentos](https://atomgit.com/openairymax/agentos)

## 联系我们

- **官方网站**: [spharx.cn](https://spharx.cn)
- **代码托管**: [AtomGit](https://atomgit.com/openairymax) · [Gitee](https://gitee.com/spharx) · [GitHub](https://github.com/OpenAirymax)
- **社区交流**: 欢迎通过 Issues、Discussions 参与讨论

---

<div align="center">

© 2026 OpenAirymax Organization. All Rights Reserved.

</div>
