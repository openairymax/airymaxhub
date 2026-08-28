## About

OpenAirymax is an open-source organization focused on agent engineering.

## Projects

OpenAirymax releases two co-designed systems at different layers of the stack:

- **AirymaxRT** (Agent Runtime Platform Engineering) — a cross-platform (Linux, Windows, macOS) execution base for AI agents, delivering a stable, production-grade agent runtime.
- **AirymaxOS** (Agent Operating System) — a Linux-based agent OS (Linux 6.6 / 7.1), purpose-built for agent workloads — a truly native agent operating system.
- RT and OS share the same architecture; composed together they form the complete Airymax stack, and either one also runs independently.

## Structure

The `airymaxhub` umbrella repo:

- **user mode** → `agent-workload` [AirymaxRT platform engineering]
- **kernel mode** → `agent-linux` [AirymaxOS operating system]

> OpenAirymax uses a multi-repo hierarchy. For the full submodule layout, URL conventions, and branching strategy, see [REPOSITORIES.md](REPOSITORIES.md).

## Community

Scan the QR code to join our Feishu (Lark) group:

<div align="left">
  <img src=".github/image/openairymax-feishu.jpg" alt="Community QR code" width="150" />
</div>

## License

Dual-licensed under **AGPL v3 + Apache 2.0**. Each leaf repo carries its own `LICENSE` file.

> Why "Airymax"? One of the project's founders, Liren Wang, believes Airymax gives agents a native runtime environment. Through deliberate systems engineering, even an agent powered by a mid-tier LLM can push its capabilities to **ultimate sublimation** under this system — reaching a higher level of functionality and performance, punching far above its weight class.

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
