# .github — airymaxhub 伞仓社区资源

> airymaxhub（Airymax 伞仓）是 **git superproject（纯容器）**：聚合
> agent-workload / agent-linux / docs / docs-closed / tools / developbuild 等子模块，
> 以及仓库级社区文件与图片资源。

**拓扑约定（2026-09 架构裁决）**：伞仓**不承载任何 CI/CD 流水线**。构建 / 测试 /
codegen / SSoT / 镜像同步 / 六平台发布等工作流全部下沉到
[agentrt 管理仓](https://atomgit.com/openairymax/agentrt)（`.github/` 目录，发布平面）。
atomgit 为 SSoT 主托管；GitHub / Gitee 仅为镜像与执行面，按需同步。

## 目录结构

```
.github/
├── README.md                      # 本文件
└── image/
    └── openairymax-feishu.jpg     # 飞书交流群二维码（README 社区入口）
```

伞仓历史版本中的 `.github/workflows/`（build-test / codegen-check / release /
ssot-validate / sync-mirror）与 `.github/scripts/` 已迁移至 agentrt 仓。

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
