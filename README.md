## About

OpenAirymax is an open-source organization focused on agent-native infrastructure.

## Projects

Two co-designed systems, operating at different layers of the stack:

- **AirymaxRT** (the Agent Runtime) — a cross-platform (Linux, Windows, macOS) execution base for AI agents. Built for end users and developers who need a production-grade, industrial-strength runtime.
- **AirymaxOS** (the Agent Operating System) — a Linux-based distro (Linux 6.6 / 7.1), purpose-built for agent workloads. Optimized performance and stability, targeting the open-source community and professional developers.

> Same architecture. Same engineering standards. Compose them together for the full Airymax stack, or run either one standalone — both are first-class products.

## Structure

The `airymaxhub` umbrella repo:

- **user mode** → `agent-workload` &nbsp; [AirymaxRT user-space engineering super-repo (renamed from `agent-runtim` in v0.1.4): agentrt core runtime + sdk + ecosystem + products]
- **kernel mode** → `agent-linux` &nbsp; [AirymaxOS Distribution; renamed from `agentrt-linux` in v0.1.3]

> OpenAirymax uses a multi-repo hierarchy. For the full submodule layout, URL conventions, and branching strategy, see [REPOSITORIES.md](REPOSITORIES.md).

## License

Dual-licensed under **AGPL v3 + Apache 2.0**. Each leaf repo carries its own `LICENSE` file.

---

### Why "Airymax"?

One of the project founders, Liren Wang, explains it like this: Airymax gives agents a native runtime — not an afterthought, but the foundation itself. Through deliberate systems engineering, even an agent running on a mid-tier model can reach a state of *ultimate sublimation*, punching far above its weight class. The architecture doesn't just support the agent — it elevates it to a new level of capability.

That's the idea behind the name.

---

Copyright (c) 2025-2026 SPHARX Ltd. All Rights Reserved.
