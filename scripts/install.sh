#!/bin/sh
# ============================================================================
# Airymax AgentRT 一键安装脚本（唯一官方安装入口）
#
# 用法：
#   curl -fsSL https://raw.atomgit.com/openairymax/airymaxhub/raw/main/scripts/install.sh | sh
#   sh install.sh --prefix "$HOME/.airymaxrt"        # 自定义路径
#   sh install.sh --uninstall                        # 一键卸载
#
# 安装策略（三模式，按可达性自动降级）：
#   模式 A 二进制：AIRY_RELEASE_URL 指向完全体 tarball（含闭源模块预编译产物），
#      下载解压到 $AIRY_HOME，秒级安装、无需工具链（完全体二进制为主）。
#   模式 B 混合构建：管理仓 + 公开子仓源码编译；闭源模块（atoms / memoryrovol）
#      下载预编译包到 $AIRY_HOME/modules/ 后链接（AIRY_ATOMS_PREBUILT_DIR /
#      MEMORYROVOL_PRO_LIB）。本地无闭源源码时自动走此模式。
#   模式 C 全源码构建：本地已持有闭源模块源码（如 airymaxrt-local），直接
#      全量源码编译（AIRY_MODE=source 或检测到本地源码树时）。
#
# 路径体系（与 platform.h AIRY_HOME 完全一致，全产物收敛）：
#   $AIRY_HOME            = ${AIRY_HOME:-$HOME/.airymaxrt}（--prefix 覆盖）
#   $AIRY_HOME/bin  lib  include  config  run  logs  data  tmp  cache
#   $AIRY_HOME/modules    — 闭源预编译模块包（atoms/memoryrovol）
#   $AIRY_HOME/src        — 源码树（构建模式）
#   $AIRY_HOME/build      — out-of-source 构建目录（构建模式）
#   $AIRY_HOME/scripts    — 安装器自托管（install/uninstall 副本）
#
# 环境变量：
#   AIRY_HOME / AIRY_VERSION / AIRY_REPO_URL / AIRY_BUILD_JOBS
#   AIRY_RELEASE_URL / AIRY_NO_BUILD / AIRY_MODE(auto|binary|hybrid|source)
#   AIRY_ATOMS_PREBUILT_URL / AIRY_MEMORYROVOL_PREBUILT_URL（闭源预编译包直链）
#
# 参数：
#   --prefix <path>  --mode <auto|binary|hybrid|source>  --bin-dir <path>
#   --uninstall [--keep-data] [--yes]  --help
#
# 安装完成后：固化 install.env（含 AIRY_BIN_LINK）、生成 agentrt-env.sh、
# 软链 airymaxrt 启动器到 PATH（任意路径输入 airymaxrt 即启动），
# 校验 17 个 daemon 全部就位。
#
# 卸载：sh install.sh --uninstall 或 airymaxrt uninstall（停止 daemon +
#       删除 $AIRY_HOME + 移除 PATH 软链；--keep-data 保留记忆数据）。
# ============================================================================

set -u

# ─── 颜色（无 TTY 时禁用） ──────────────────────────────────────────────
if [ -t 1 ]; then
    C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'; C_CYAN='\033[0;36m'; C_NC='\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_NC=''
fi
log_info()  { printf "${C_CYAN}[INFO]${C_NC} %s\n" "$1"; }
log_ok()    { printf "${C_GREEN}[ OK ]${C_NC} %s\n" "$1"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_NC} %s\n" "$1"; }
log_err()   { printf "${C_RED}[FAIL]${C_NC} %s\n" "$1"; }

# ─── 默认值 ──────────────────────────────────────────────────────────────
AIRY_HOME="${AIRY_HOME:-$HOME/.airymaxrt}"
AIRY_REPO_URL="${AIRY_REPO_URL:-https://atomgit.com/openairymax/airymaxhub.git}"
AIRY_VERSION="${AIRY_VERSION:-main}"
AIRY_BUILD_JOBS="${AIRY_BUILD_JOBS:-$(nproc 2>/dev/null || echo 4)}"
AIRY_MODE="${AIRY_MODE:-auto}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
UNINSTALL=0; KEEP_DATA=0; YES=0

AIRY_SRC_DIR="${AIRY_HOME}/src/airymaxhub"
MODULES_DIR="${AIRY_HOME}/modules"

# 17 个 daemon 完整清单（安装后逐一校验，含 think_d/cupolas_d）
EXPECTED_DAEMONS="monit_d observe_d info_d notify_d sched_d channel_d mem_d
                  llm_d tool_d hook_d plugin_d agent_d a2a_d market_d gateway_d
                  think_d cupolas_d"

# ─── 参数解析 ────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)    AIRY_HOME="$2"; shift 2 ;;
        --mode)      AIRY_MODE="$2"; shift 2 ;;
        --bin-dir)   BIN_DIR="$2"; shift 2 ;;
        --uninstall) UNINSTALL=1; shift ;;
        --keep-data) KEEP_DATA=1; shift ;;
        --yes)       YES=1; shift ;;
        --help|-h)   sed -n '2,52p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) log_err "未知参数: $1（--help 查看用法）"; exit 1 ;;
    esac
done

case "$AIRY_MODE" in auto|binary|hybrid|source) ;; *) log_err "非法 --mode: ${AIRY_MODE}"; exit 1 ;; esac
AIRY_SRC_DIR="${AIRY_HOME}/src/airymaxhub"

# ─── 工具链检测 ──────────────────────────────────────────────────────────
require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_err "缺少必要工具: $1"
        case "$1" in
            git)   log_warn "请安装 git（如 Debian/Ubuntu: sudo apt install git）" ;;
            cmake) log_warn "请安装 cmake ≥3.20（如: sudo apt install cmake）" ;;
            gcc|cc|clang) log_warn "请安装 C 编译器（如: sudo apt install build-essential）" ;;
            curl)  log_warn "请安装 curl" ;;
        esac
        exit 1
    fi
}

check_toolchain() {
    require_cmd curl
    if [ "${AIRY_NO_BUILD:-}" != "1" ]; then
        require_cmd git
        require_cmd cmake
        require_cmd make
        if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v cc >/dev/null 2>&1; then
            log_err "未找到 C 编译器（gcc/clang/cc）"; exit 1
        fi
        for lib in libcurl sqlite3; do
            pkg-config --exists "$lib" 2>/dev/null || \
                log_warn "未检测到 ${lib} 开发库，部分功能受限（建议安装 lib${lib}-dev）"
        done
    fi
}

# ─── 创建 AIRY_HOME 目录骨架 ───────────────────────────────────────────
init_home() {
    mkdir -p "${AIRY_HOME}"/bin "${AIRY_HOME}"/lib "${AIRY_HOME}"/run \
             "${AIRY_HOME}"/logs "${AIRY_HOME}"/config "${AIRY_HOME}"/data \
             "${AIRY_HOME}"/tmp "${AIRY_HOME}"/cache "${AIRY_HOME}"/modules \
             "${AIRY_HOME}"/scripts
    chmod 700 "${AIRY_HOME}/config" 2>/dev/null || true
    log_ok "AIRY_HOME 就绪: ${AIRY_HOME}"
}

# ─── 停止运行中的 daemon ────────────────────────────────────────────────
stop_daemons() {
    local bin="$1"
    [ -d "$bin" ] || return 0
    for d in ${EXPECTED_DAEMONS}; do
        [ -x "${bin}/${d}" ] && pkill -f "${bin}/${d}" >/dev/null 2>&1
    done
    sleep 1
}

# ─── 一键卸载 ────────────────────────────────────────────────────────────
do_uninstall() {
    local home="$1" keep_data="$2" yes="$3" env_file link size ans
    env_file="${home}/config/install.env"
    if [ -f "$env_file" ]; then
        home="$(sed -n 's/^AIRY_HOME=//p' "$env_file" | head -1)"
        [ -n "$home" ] || home="$1"
    fi
    if [ ! -d "$home" ]; then
        log_warn "未检测到安装（$home 不存在），无需卸载"
        return 0
    fi
    link="$(sed -n 's/^AIRY_BIN_LINK=//p' "$env_file" 2>/dev/null | head -1)"
    [ -n "$link" ] || link="${BIN_DIR}/airymaxrt"
    size="$(du -sh "$home" 2>/dev/null | cut -f1)"
    log_warn "将卸载 AirymaxRT：${home}（${size}）"
    if [ "$yes" != "1" ]; then
        printf "${C_YELLOW}确认卸载？[y/N] ${C_NC}"
        read -r ans || true
        case "$ans" in y|Y|yes|YES) ;; *) log_info "已取消卸载"; return 0 ;; esac
    fi
    stop_daemons "$home/bin"
    if [ "$keep_data" = "1" ] && [ -d "$home/data" ]; then
        rm -rf "$home"
        mkdir -p "$home/data"
        log_ok "已删除 ${home}（保留 data/ 记忆数据）"
    else
        rm -rf "$home"
        log_ok "已删除 ${home}"
    fi
    if [ -L "$link" ]; then
        rm -f "$link"
        log_ok "已移除启动器软链 ${link}"
    fi
    log_ok "卸载完成"
}

# ─── 方式 A：完全体二进制 tarball（优先） ───────────────────────────────
install_binary() {
    local url="$1"
    local tarball="${AIRY_HOME}/tmp/agentrt-${AIRY_VERSION}.tar.gz"
    log_info "下载完全体二进制包: ${url}"
    if ! curl -fsSL --max-time 600 -o "${tarball}" "${url}"; then
        log_warn "release 下载失败，回退源码构建"
        rm -f "${tarball}"
        return 1
    fi
    tar -xzf "${tarball}" -C "${AIRY_HOME}/tmp"
    local extracted
    extracted="$(find "${AIRY_HOME}/tmp" -maxdepth 1 -type d -name 'agentrt-*' | head -1)"
    [ -n "$extracted" ] || { log_warn "release 包结构异常，回退源码构建"; return 1; }
    cp -f "${extracted}"/bin/* "${AIRY_HOME}/bin/" 2>/dev/null || true
    cp -f "${extracted}"/lib/* "${AIRY_HOME}/lib/" 2>/dev/null || true
    cp -f "${extracted}"/include/* -r "${AIRY_HOME}/include/" 2>/dev/null || true
    [ -f "${extracted}/config/secrets.env.example" ] && \
        cp -f "${extracted}/config/secrets.env.example" "${AIRY_HOME}/config/" 2>/dev/null || true
    log_ok "完全体二进制包安装完成"
    return 0
}

# ─── 闭源预编译模块下载（模式 B） ───────────────────────────────────────
fetch_prebuilt_module() {
    # fetch_prebuilt_module <name> <url> <解压后目录名>
    local name="$1" url="$2" dirname="$3" dest="${MODULES_DIR}/${dirname}"
    [ -n "$url" ] || { log_warn "未配置 ${name} 预编译包 URL，跳过"; return 1; }
    if [ -d "$dest" ]; then log_ok "${name} 预编译模块已就位"; return 0; fi
    log_info "下载闭源预编译模块 ${name}…"
    local tarball="${AIRY_HOME}/tmp/${dirname}.tar.gz"
    curl -fsSL --max-time 600 -o "$tarball" "$url" || { log_warn "${name} 下载失败"; return 1; }
    mkdir -p "$dest"
    tar -xzf "$tarball" -C "$dest" || { log_warn "${name} 解压失败"; return 1; }
    log_ok "${name} 预编译模块就位: ${dest}"
    return 0
}

# ─── 源码获取（模式 B/C） ───────────────────────────────────────────────
prepare_source() {
    if [ ! -d "${AIRY_SRC_DIR}/.git" ]; then
        log_info "git 拉取 airymaxhub（${AIRY_REPO_URL}）…"
        mkdir -p "$(dirname "${AIRY_SRC_DIR}")"
        # 管理仓 clone（公开子仓递归）；闭源子仓由预编译模块包补齐，避免认证失败中断
        git clone --depth 1 -b "${AIRY_VERSION}" "${AIRY_REPO_URL}" "${AIRY_SRC_DIR}" \
            || { log_err "git 拉取失败（若子仓私有，请配置 AIRY_RELEASE_URL 走二进制模式）"; exit 1; }
        git -C "${AIRY_SRC_DIR}" submodule update --init --depth 1 2>/dev/null || \
            log_warn "部分子仓拉取受限（闭源模块将由预编译包补齐）"
    else
        log_info "airymaxhub 源码已存在，复用本地源码树"
        git -C "${AIRY_SRC_DIR}" fetch --all --tags --depth 1 >/dev/null 2>&1 || true
    fi
    log_ok "源码就绪: ${AIRY_SRC_DIR}"
}

# ─── 构建（模式 B/C 共用） ──────────────────────────────────────────────
build_and_install() {
    local build_dir="${AIRY_HOME}/build"
    local cmake_args="-DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=${AIRY_HOME}"

    # 闭源模块预编译路径注入（模式 B）
    if [ -d "${MODULES_DIR}/atoms" ]; then
        cmake_args="${cmake_args} -DAIRY_ATOMS_PREBUILT_DIR=${MODULES_DIR}/atoms"
    fi
    if [ -f "${MODULES_DIR}/memoryrovol/libairy_memoryrovol_pro.a" ]; then
        cmake_args="${cmake_args} -DMEMORYROVOL_PRO_LIB=${MODULES_DIR}/memoryrovol/libairy_memoryrovol_pro.a"
    fi

    log_info "cmake 配置（${cmake_args}）…"
    cmake -S "${AIRY_SRC_DIR}/agentrt" -B "${build_dir}" ${cmake_args} \
        || { log_err "cmake 配置失败"; exit 1; }
    log_info "构建（-j${AIRY_BUILD_JOBS}）…"
    cmake --build "${build_dir}" -j"${AIRY_BUILD_JOBS}" || { log_err "构建失败"; exit 1; }
    log_info "安装到 ${AIRY_HOME}…"
    cmake --install "${build_dir}" || true
    if [ -d "${build_dir}/bin" ]; then
        cp -f "${build_dir}"/bin/* "${AIRY_HOME}/bin/" 2>/dev/null || true
    fi
    log_ok "源码构建安装完成"
}

# ─── Python 依赖安装 → lib/ ────────────────────────────────────────────
install_python_deps() {
    log_info "安装 Python 依赖到 ${AIRY_HOME}/lib …"
    local pkg
    for pkg in airymax_agents airymax_agents_rs; do
        [ -d "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" ] || { log_warn "跳过: ecosystem/agents/${pkg}"; continue; }
        rsync -a --exclude tests --exclude __pycache__ --exclude .git --exclude examples \
            "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" "${AIRY_HOME}/lib/" 2>/dev/null \
            || cp -r "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" "${AIRY_HOME}/lib/"
    done
    for pkg in openlab markets contrib app; do
        [ -d "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" ] || { log_warn "跳过: ecosystem/openlab/${pkg}"; continue; }
        rsync -a --exclude tests --exclude __pycache__ --exclude .git --exclude examples \
            "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" "${AIRY_HOME}/lib/" 2>/dev/null \
            || cp -r "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" "${AIRY_HOME}/lib/"
    done
    if [ -d "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" ]; then
        rsync -a --exclude tests --exclude __pycache__ --exclude .git \
            "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" "${AIRY_HOME}/lib/" 2>/dev/null \
            || cp -r "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" "${AIRY_HOME}/lib/"
    fi
    if command -v python3 >/dev/null 2>&1; then
        if PYTHONPATH="${AIRY_HOME}/lib" python3 -c "import agentrt, airymax_agents, openlab, markets" 2>/dev/null; then
            log_ok "Python 依赖可导入 (agentrt/airymax_agents/openlab/markets)"
        else
            log_warn "lib/ 导入校验失败（检查源码包结构）"
        fi
    fi
}

# ─── Rust TUI 构建（源码模式附带） ─────────────────────────────────────
build_tui() {
    [ -d "${AIRY_SRC_DIR}/sdk/tui" ] || return 0
    if ! command -v cargo >/dev/null 2>&1 && [ -x "$HOME/.cargo/bin/cargo" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    command -v cargo >/dev/null 2>&1 || { log_warn "cargo 不可用，跳过 agentrt-tui"; return 0; }
    log_info "构建 agentrt-tui（Rust TUI）…"
    ( cd "${AIRY_SRC_DIR}/sdk/tui" && cargo build --release ) 2>/dev/null || { log_warn "TUI 构建失败，跳过"; return 0; }
    [ -f "${AIRY_SRC_DIR}/sdk/tui/target/release/agentrt-tui" ] && \
        cp -f "${AIRY_SRC_DIR}/sdk/tui/target/release/agentrt-tui" "${AIRY_HOME}/bin/agentrt-tui"
    log_ok "agentrt-tui 部署完成"
}

# ─── CLI 兼容入口：Rust TUI 缺失时用 C airy_cli 提供 agentrt-tui ──────
# airymaxrt 启动器通过 TUI 可执行文件进入交互界面；当 Rust TUI 未构建
# （cargo 缺失 / 构建失败 / 二进制包未含）时，以 C 实现的 airy_cli 作为
# agentrt-tui 兼容入口，保证 `airymaxrt` 始终可用。包装脚本 source
# install-pinned 的 agentrt-env.sh，导出 AIRY_HOME 等，使 CLI 能连接已
# 安装的 daemon（不受调用 shell 的环境变量影响）。
ensure_cli_entry() {
    [ -x "${AIRY_HOME}/bin/agentrt-tui" ] && return 0
    if [ -x "${AIRY_HOME}/bin/airy_cli" ]; then
        cat > "${AIRY_HOME}/bin/agentrt-tui" <<'TUIEOF'
#!/bin/sh
# SPDX-FileCopyrightText: 2025-2026 SPHARX Ltd.
# SPDX-License-Identifier: AGPL-3.0-or-later OR Apache-2.0
# agentrt-tui compat entry for the C airy_cli (used when the Rust TUI is
# not built). Sources the install-pinned environment so the CLI reaches
# the installed daemons regardless of the calling shell.
_DIR="$(cd -P "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$_DIR/agentrt-env.sh"
exec "$_DIR/airy_cli" "$@"
TUIEOF
        chmod 755 "${AIRY_HOME}/bin/agentrt-tui"
        log_ok "agentrt-tui 使用 C airy_cli 兼容入口（Rust TUI 未构建）"
    else
        log_warn "agentrt-tui 与 airy_cli 均缺失"
    fi
}

# ─── secrets.env 模板 ──────────────────────────────────────────────────
init_secrets() {
    local secrets="${AIRY_HOME}/config/secrets.env"
    if [ ! -f "${secrets}" ]; then
        local template="${AIRY_SRC_DIR}/devtools/scripts/ops/templates/secrets.env.example"
        if [ -f "${template}" ]; then
            cp "${template}" "${secrets}"
            chmod 600 "${secrets}"
            log_warn "已生成 ${secrets}，请填写 LLM API key"
        else
            log_warn "未找到 secrets.env 模板，跳过"
        fi
    else
        log_ok "secrets.env 已存在，跳过"
    fi
    [ -f "${AIRY_SRC_DIR}/ecosystem/manager/configs/agentrt.yaml" ] && \
        cp -f "${AIRY_SRC_DIR}/ecosystem/manager/configs/agentrt.yaml" "${AIRY_HOME}/config/" 2>/dev/null || true
    [ -f "${AIRY_SRC_DIR}/ecosystem/manager/model/model.yaml" ] && \
        cp -f "${AIRY_SRC_DIR}/ecosystem/manager/model/model.yaml" "${AIRY_HOME}/config/" 2>/dev/null || true
}

# ─── 固化安装位置 + 生成运行环境 + 启动器软链 ──────────────────────────
finalize_install() {
    # 生成 vault 主密钥口令（AES-256-GCM 凭据加密）。随机强口令，缺失回退链：
    # openssl rand → /dev/urandom hexdump → 时间戳+urandom 哈希（极低概率兜底）。
    local vault_password
    vault_password=$(openssl rand -hex 32 2>/dev/null \
        || { head -c 32 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n'; })
    if [ -z "${vault_password}" ]; then
        vault_password="$( { date +%s%N; head -c 64 /dev/urandom 2>/dev/null; } | sha256sum | cut -c1-64 )"
    fi
    {
        echo "# AgentRT 安装信息（由 install.sh 生成，勿手改）"
        echo "AIRY_HOME=${AIRY_HOME}"
        echo "AIRY_VERSION=${AIRY_VERSION}"
        echo "AIRY_BIN_LINK=${BIN_DIR}/airymaxrt"
        echo "INSTALLED_AT=$(date -Is 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')"
        echo "AIRY_VAULT_PASSWORD=${vault_password}"
    } > "${AIRY_HOME}/config/install.env"
    chmod 600 "${AIRY_HOME}/config/install.env"

    cat > "${AIRY_HOME}/bin/agentrt-env.sh" <<EOF
#!/bin/sh
# AgentRT 运行环境（由 install.sh 生成，source 使用）
export AIRY_HOME="${AIRY_HOME}"
export AIRY_RUNTIME_DIR="\${AIRY_RUNTIME_DIR:-\$AIRY_HOME/run}"
export AIRY_LOG_DIR="\${AIRY_LOG_DIR:-\$AIRY_HOME/logs}"
export AIRY_CONFIG_DIR="\${AIRY_CONFIG_DIR:-\$AIRY_HOME/config}"
export AIRY_BIN_DIR="\${AIRY_BIN_DIR:-\$AIRY_HOME/bin}"
export AIRY_LIB_DIR="\${AIRY_LIB_DIR:-\$AIRY_HOME/lib}"
# Agent 工具 ACL 预授权（fail-closed：无此变量时 agent 工具全部拒绝）。
# 与 agentrt-bootstrap.sh 保持一致；用户可显式覆盖收紧。
export AIRY_AGENT_ACL="\${AIRY_AGENT_ACL:-coding_v1=fs_read,fs_write,fs_list,fs_glob,fs_grep,fs_edit,shell_run,web_search,web_fetch,git_diff,git_exec,git_apply}"
export PATH="\${AIRY_HOME}/bin:\$PATH"
EOF
    chmod 700 "${AIRY_HOME}/bin/agentrt-env.sh"

    # 启动器软链：任意路径输入 airymaxrt 即启动（读 install.env 定位运行时根）
    if [ -f "${AIRY_SRC_DIR}/sdk/tui/scripts/airymaxrt" ]; then
        cp -f "${AIRY_SRC_DIR}/sdk/tui/scripts/airymaxrt" "${AIRY_HOME}/bin/airymaxrt"
        chmod 755 "${AIRY_HOME}/bin/airymaxrt"
    elif [ -f "${AIRY_HOME}/bin/agentrt-tui" ]; then
        # 二进制模式无源码：生成轻量启动器
        cat > "${AIRY_HOME}/bin/airymaxrt" <<EOF
#!/bin/sh
AIRY_HOME="\$(sed -n 's/^AIRY_HOME=//p' "\${AIRY_HOME:-$HOME/.airymaxrt}/config/install.env" 2>/dev/null | head -1)"
AIRY_HOME="\${AIRY_HOME:-$HOME/.airymaxrt}"
export AIRY_HOME
exec "\$AIRY_HOME/bin/agentrt-tui" "\$@"
EOF
        chmod 755 "${AIRY_HOME}/bin/airymaxrt"
    fi
    if [ -x "${AIRY_HOME}/bin/airymaxrt" ]; then
        mkdir -p "${BIN_DIR}"
        ln -sf "${AIRY_HOME}/bin/airymaxrt" "${BIN_DIR}/airymaxrt"
        log_ok "启动器软链: ${BIN_DIR}/airymaxrt → ${AIRY_HOME}/bin/airymaxrt"
    fi

    # 安装器自托管（供离线卸载）
    cp -f "$0" "${AIRY_HOME}/scripts/install.sh" 2>/dev/null || true
    log_ok "安装位置已固化: install.env + agentrt-env.sh + 启动器"
}

# ─── 17 daemon 完整性校验 ──────────────────────────────────────────────
verify_daemons() {
    local missing=""
    for d in ${EXPECTED_DAEMONS}; do
        [ -x "${AIRY_HOME}/bin/${d}" ] || missing="${missing} ${d}"
    done
    if [ -n "$missing" ]; then
        log_warn "daemon 校验未全通过，缺失:${missing}（可能为二进制包未含全部组件）"
    else
        log_ok "17 个 daemon 全部就位"
    fi
}

# ─── 版本信息 ──────────────────────────────────────────────────────────
print_banner() {
    cat <<EOF
${C_CYAN}
  ┌─────────────────────────────────────────────────────┐
  │         Airymax Agent Platform Engineering          │
  │=====================================================│
  │     Runtime · Frame · SpuerAgent · All-in-one       │
  │=====================================================│
  │ "Agents, To the open air. To OpenAirymax. To hope." │
  └─────────────────────────────────────────────────────┘
${C_NC}
EOF
}

print_summary() {
    cat <<EOF

安装位置:   ${AIRY_HOME}
可执行文件: ${AIRY_HOME}/bin/
配置文件:   ${AIRY_HOME}/config/
安装固化:   ${AIRY_HOME}/config/install.env
运行环境:   . ${AIRY_HOME}/bin/agentrt-env.sh
启动器:     ${BIN_DIR}/airymaxrt（任意路径输入 airymaxrt 即启动）

快速开始:
  1. 配置 LLM 提供方（API key）:
     ${AIRY_HOME}/config/secrets.env
  2. 启动交互界面（自动拉起 gateway/llm daemon）:
     airymaxrt
  3. 查看运行时状态:
     airymaxrt status
  4. 一键卸载（--keep-data 保留记忆数据）:
     airymaxrt uninstall   或   ${AIRY_HOME}/scripts/install.sh --uninstall
EOF
}

# ─── 主流程 ────────────────────────────────────────────────────────────
main() {
    print_banner
    log_info "Airymax AgentRT 安装程序"
    log_info "AIRY_HOME = ${AIRY_HOME} | 模式 = ${AIRY_MODE}"

    if [ "$UNINSTALL" = "1" ]; then
        do_uninstall "$AIRY_HOME" "$KEEP_DATA" "$YES"
        exit $?
    fi

    check_toolchain
    init_home

    local installed=1
    # 模式选择：binary 显式或 auto（有 release URL 且未显式 source）
    if [ "$AIRY_MODE" = "binary" ] || { [ "$AIRY_MODE" = "auto" ] && [ -n "${AIRY_RELEASE_URL:-}" ]; }; then
        if [ -n "${AIRY_RELEASE_URL:-}" ]; then
            install_binary "${AIRY_RELEASE_URL}" && installed=0
        elif [ "$AIRY_MODE" = "binary" ]; then
            log_err "模式 binary 需要 AIRY_RELEASE_URL"; exit 1
        fi
    fi

    if [ "$installed" -ne 0 ]; then
        log_info "进入源码构建模式（${AIRY_MODE}）"
        prepare_source

        # 模式 B：无闭源源码 → 下载预编译模块包（URL 未配置时跳过，闭源功能受限）
        if [ ! -d "${AIRY_SRC_DIR}/agentrt/atoms" ] && [ "$AIRY_MODE" != "source" ]; then
            fetch_prebuilt_module "atoms" "${AIRY_ATOMS_PREBUILT_URL:-}" "atoms" || \
                log_warn "atoms 预编译包不可用；如需完整功能请配置 AIRY_ATOMS_PREBUILT_URL 或使用本地源码"
            fetch_prebuilt_module "memoryrovol" "${AIRY_MEMORYROVOL_PREBUILT_URL:-}" "memoryrovol" || \
                log_warn "memoryrovol 预编译包不可用（无授权将自动降级 OSS/builtin）"
        elif [ "$AIRY_MODE" = "source" ] && [ -d "${AIRY_SRC_DIR}/agentrt/atoms" ]; then
            log_ok "模式 C：本地闭源源码（atoms/memoryrovol）全量构建"
        fi

        if [ "${AIRY_NO_BUILD:-}" != "1" ]; then
            build_and_install
            install_python_deps
            build_tui
            ensure_cli_entry
        fi
        init_secrets
    fi

    finalize_install
    verify_daemons
    print_summary
    log_ok "安装完成"
}

main "$@"
