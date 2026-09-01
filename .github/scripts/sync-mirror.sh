#!/usr/bin/env bash
#
# sync-mirror.sh — umbrella + 全部子模块 → GitHub / Gitee 双镜像
#
# 根因修复（旧版三大缺陷）：
#   1. 循环依赖死锁：旧 workflow 用 checkout submodules:true，需要从
#      GitHub 拉子模块，而子模块镜像仓正是本工作流要创建的 → run #82
#      9 秒即败，tag 从未到达 GitHub，release.yml 无法触发。
#   2. gh repo create --confirm 已在 gh 2.x 移除 → 缺失仓自动创建静默
#      失败（"warn: skipping"），镜像永久停留在旧提交。
#   3. set -e 下单仓推送失败中断整条同步链，无汇总、无隔离。
#
# 新模型：
#   - 源 = atomgit（SSoT）：clone --mirror + push --mirror（全 refs，
#     镜像语义）。公开子仓匿名可读；私有子仓（atoms）需 ATOMGIT_TOKEN。
#   - 子模块树以各仓 HEAD:.gitmodules 动态 BFS 解析，新增子模块零维护。
#   - GitHub 缺仓用 gh CLI 创建；Gitee 缺仓用 API v5 创建；私有名单
#     （atoms）建私有，防内容泄露。
#   - 每仓错误隔离，末尾汇总，任一失败 exit 1。
#   - umbrella 最后同步：tag 推上 GitHub 触发 release.yml 时，子模块
#     镜像已全部就绪（release.yml 从 GitHub 拉子模块）。

set -uo pipefail

GH_ORG="openairymax"
GT_ORG="openairymax"
UMBRELLA="airymaxhub"

# 闭源子模块：无公网镜像，跳过（含历史名兜底）
SKIP_LIST=" closed-docs closed-dev-build build-closed devbuild-closed developbuild docs-closed memoryrovol "
# 私有仓（atomgit/GitHub 均为 private）：缺仓创建时必须 private
PRIVATE_LIST=" atoms "

FAILED=()
OK=()
SEEN=" "
QUEUE=()

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log() { echo "$@"; }

# 源 clone URL：有 ATOMGIT_TOKEN 则带认证（覆盖私有仓），否则匿名
src_url() {
  if [ -n "${ATOMGIT_TOKEN:-}" ]; then
    printf 'https://oauth2:%s@atomgit.com/%s/%s.git' "$ATOMGIT_TOKEN" "$GH_ORG" "$1"
  else
    printf 'https://atomgit.com/%s/%s.git' "$GH_ORG" "$1"
  fi
}

is_private() { case "$PRIVATE_LIST" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
is_skip()    { case "$SKIP_LIST"    in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# .gitmodules 文件 → 子模块仓名列表（path 的 basename，本树约定仓名=basename）
# 注意：--get-regexp 只匹配 key 名（形如 submodule.<name>.path，以 .path
# 结尾），故锚点必须是 \.path$；值（路径）从第二列取。
parse_submodules() {
  [ -s "$1" ] || return 0
  git config -f "$1" --get-regexp '\.path$' 2>/dev/null \
    | awk '{print $2}' | while read -r p; do basename "$p"; done
}

# 入队（去重交给主循环 SEEN）
enqueue() {
  local s
  while read -r s; do
    [ -n "$s" ] && QUEUE+=("$s")
  done < <(parse_submodules "$1")
}

ensure_github_repo() {
  gh repo view "${GH_ORG}/$1" >/dev/null 2>&1 && return 0
  local vis="--public"
  is_private "$1" && vis="--private"
  # gh 2.x 无 --confirm；非交互环境下 create 直接生效
  if gh repo create "${GH_ORG}/$1" "$vis" >/dev/null 2>&1; then
    log "  created github.com/${GH_ORG}/$1"
    return 0
  fi
  log "  ERROR: cannot create github.com/${GH_ORG}/$1"
  return 1
}

ensure_gitee_repo() {
  curl -fsS -o /dev/null \
    "https://gitee.com/api/v5/repos/${GT_ORG}/$1?access_token=${GT_TOKEN}" && return 0
  local vis="false"
  is_private "$1" && vis="true"
  if curl -fsS -o /dev/null -X POST \
      "https://gitee.com/api/v5/orgs/${GT_ORG}/repos" \
      --data-urlencode "access_token=${GT_TOKEN}" \
      --data-urlencode "name=$1" \
      --data-urlencode "private=${vis}" \
      --data-urlencode "auto_init=false"; then
    log "  created gitee.com/${GT_ORG}/$1"
    return 0
  fi
  log "  ERROR: cannot create gitee.com/${GT_ORG}/$1"
  return 1
}

# 单仓同步：atomgit mirror clone → push --mirror 到 GitHub + Gitee。
# 克隆后读 HEAD:.gitmodules 将嵌套子模块入队（BFS）；目录用完即删（控磁盘，
# kernel 仓 mirror 约 2.5GB）。
sync_repo() {
  local name="$1"
  local dir="$WORK/${name}.git"
  log "=== $name ==="

  if ! timeout 900 git clone --mirror -q "$(src_url "$name")" "$dir"; then
    log "  FAIL: clone from atomgit (missing repo or token cannot read)"
    FAILED+=("$name")
    return 1
  fi

  local gm="$WORK/${name}.gitmodules"
  : > "$gm"
  git -C "$dir" show HEAD:.gitmodules > "$gm" 2>/dev/null || true
  enqueue "$gm"
  rm -f "$gm"

  local rc=0
  if ensure_github_repo "$name"; then
    timeout 900 git -C "$dir" push --mirror -q \
      "https://x-access-token:${GH_TOKEN}@github.com/${GH_ORG}/${name}.git" \
      || { log "  FAIL: push github"; rc=1; }
  else
    rc=1
  fi
  if ensure_gitee_repo "$name"; then
    timeout 900 git -C "$dir" push --mirror -q \
      "https://oauth2:${GT_TOKEN}@gitee.com/${GT_ORG}/${name}.git" \
      || { log "  FAIL: push gitee"; rc=1; }
  else
    rc=1
  fi

  rm -rf "$dir"
  if [ "$rc" -eq 0 ]; then
    OK+=("$name")
    log "  done"
  else
    FAILED+=("$name")
  fi
  return "$rc"
}

# umbrella 自身：checkout 自 GitHub（触发 ref），从 atomgit 补全 tags
# （v0.1.8 等发布 tag 只存在于 atomgit），再推 GitHub + Gitee。
# main 用非 force push（分叉时大声失败而非静默覆盖）；tag 用 --force
# （tag 必须与 SSoT 一致，镜像语义）。
sync_umbrella() {
  log "=== $UMBRELLA (umbrella) ==="
  local rc=0
  git -C "$GITHUB_WORKSPACE" fetch -q "$(src_url "$UMBRELLA")" \
    '+refs/tags/*:refs/tags/*' \
    || log "  warn: umbrella tags fetch from atomgit failed"
  local pair label url
  for pair in \
    "github|https://x-access-token:${GH_TOKEN}@github.com/${GH_ORG}/${UMBRELLA}.git" \
    "gitee|https://oauth2:${GT_TOKEN}@gitee.com/${GT_ORG}/${UMBRELLA}.git"; do
    label="${pair%%|*}"
    url="${pair#*|}"
    git -C "$GITHUB_WORKSPACE" push -q "$url" \
      'refs/heads/main:refs/heads/main' \
      || { log "  FAIL: umbrella push $label (main)"; rc=1; }
    git -C "$GITHUB_WORKSPACE" push -q --force --tags "$url" \
      || { log "  FAIL: umbrella push $label (tags)"; rc=1; }
  done
  if [ "$rc" -eq 0 ]; then
    OK+=("$UMBRELLA")
    log "  done"
  else
    FAILED+=("$UMBRELLA")
  fi
}

# ─── 主流程 ────────────────────────────────────────────────────────────

# 1) 种子：umbrella 工作树的直接子模块
gm="$WORK/umbrella.gitmodules"
git -C "$GITHUB_WORKSPACE" show HEAD:.gitmodules > "$gm" 2>/dev/null || : > "$gm"
enqueue "$gm"
rm -f "$gm"

# 2) BFS 全子模块树（深度 ≤3：umbrella → L1 → L2 → L3）
while [ "${#QUEUE[@]}" -gt 0 ]; do
  name="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")
  case "$SEEN" in *" ${name} "*) continue ;; esac
  SEEN="${SEEN}${name} "
  if is_skip "$name"; then
    log "=== $name === skip (closed source)"
    continue
  fi
  sync_repo "$name" || true
done

# 3) umbrella 最后同步（见文件头注释：保证 tag 触发 release.yml 时镜像就绪）
sync_umbrella || true

# 4) 汇总
log ""
log "================ summary ================"
log "OK     (${#OK[@]}): ${OK[*]:-}"
log "FAILED (${#FAILED[@]}): ${FAILED[*]:-}"
if [ "${#FAILED[@]}" -gt 0 ]; then
  exit 1
fi
log "all mirrors in sync"
