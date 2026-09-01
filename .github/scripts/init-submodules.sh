#!/usr/bin/env bash
#
# init-submodules.sh — CI 构建用的定向子模块检出
#
# 用法: bash .github/scripts/init-submodules.sh <path> [<path>...]
#   例: init-submodules.sh agent-workload tools
#
# 为什么不用 actions/checkout 的 submodules:true：
#   1. 全量递归会拉 agent-linux/kernel（mirror 约 2.5GB），构建完全用不到，
#      徒增时间与磁盘。
#   2. checkout@v4 的 shallow 子模块检出以 --depth=1 拉分支 tip，umbrella
#      记录的 SHA 与 tip 不一致时报 "did not contain <sha>" 直接失败。
#   3. 闭源子模块（docs-closed / developbuild / memoryrovol）在 GitHub 上
#      不存在，submodules:true 必然整体失败——这正是 tag 发布链路断裂的
#      子模块侧根因。
#
# 私有子仓（agent-workload/agentrt/atoms 在 GitHub 为 private）：用
# GH_TOKEN（org PAT）写入 ~/.netrc 认证，避免匿名 404。

set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <submodule-path> [...]" >&2
  exit 2
fi

# PAT 认证走 ~/.netrc（git https 原生凭据机制）：不改写 URL、不与
# actions/checkout 注入的 url.insteadOf 冲突。私有子仓（agentrt/atoms）
# 匿名拉取必 404，GH_TOKEN 缺失时给出明确告警。
if [ -n "${GH_TOKEN:-}" ]; then
  printf 'machine github.com\nlogin x-access-token\npassword %s\n' \
    "$GH_TOKEN" > "$HOME/.netrc"
  chmod 600 "$HOME/.netrc"
  echo "auth: ~/.netrc written for github.com (GH_TOKEN)"
else
  echo "auth: GH_TOKEN not set, private submodules (atoms) may fail"
fi

# --recursive：嵌套子模块（agentrt/*、sdk/*、ecosystem/*、products/*）
# 一并检出；update=none 的闭源条目由 git 自动跳过。
git submodule update --init --recursive -- "$@"
rc=$?

echo "--- checked out ---"
git submodule status --recursive | sed 's/^/  /' | head -60
exit "$rc"
