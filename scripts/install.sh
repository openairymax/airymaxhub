#!/bin/sh
# ============================================================================
# Airymax AgentRT 一键安装脚本（唯一官方安装入口）
#
# 用法（对标 atomcode install.sh，无本地路径暴露）：
#   curl -fsSL https://raw.atomgit.com/openairymax/airymaxhub/raw/main/scripts/install.sh | sh
#
# 安装策略（两级）：
#   1. 二进制优先：若存在已发布的 release tarball（AIRY_RELEASE_URL），
#      直接下载解压到 $AIRY_HOME，秒级安装、无需工具链。
#   2. 源码构建回退：git 拉取 airymaxhub 管理仓（含全部 submodule：
#      agentrt / devtools / ecosystem / sdk / products / docs），
#      cmake 构建后安装到 $AIRY_HOME。
#
# 路径体系（与 platform.h AIRY_HOME 完全一致）：
#   $AIRY_HOME            = ${AIRY_HOME:-$HOME/.airymaxrt}
#   $AIRY_HOME/bin        — 可执行文件（15 个 daemon + CLI）
#   $AIRY_HOME/lib        — Python 运行时依赖（airymax_agents / openlab / agentrt）
#   $AIRY_HOME/run        — socket / pid
#   $AIRY_HOME/logs       — daemon 日志
#   $AIRY_HOME/config     — agentrt.yaml / model.yaml / secrets.env / install.env
#   $AIRY_HOME/data       — 持久化数据
#   $AIRY_HOME/src        — git 拉取的源码树（仅在源码构建模式生成）
#   $AIRY_HOME/build      — out-of-source 构建目录（源码构建模式）
#
# 环境变量：
#   AIRY_HOME        — 安装根目录（默认 $HOME/.airymaxrt）
#   AIRY_VERSION     — 安装版本 tag（默认 main 分支最新）
#   AIRY_REPO_URL    — airymaxhub 管理仓（默认 https://atomgit.com/openairymax/airymaxhub.git）
#   AIRY_BUILD_JOBS  — 并行编译数（默认 nproc）
#   AIRY_NO_BUILD    — 仅拉取源码不构建（调试用）
#   AIRY_RELEASE_URL — 预编译 tarball 直链（覆盖二进制路径）
#
# 安装完成后固化安装位置到 $AIRY_HOME/config/install.env，并生成
# $AIRY_HOME/bin/agentrt-env.sh（source 后获得完整运行环境，免手动 export）。
# 校验 15 个 daemon 全部就位；Python 依赖复制到 lib/ 并做导入校验。
#
# 卸载：rm -rf "$AIRY_HOME" 即干净卸载（所有产物收敛于 AIRY_HOME）。
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

# ─── 参数 ───────────────────────────────────────────────────────────────
AIRY_HOME="${AIRY_HOME:-$HOME/.airymaxrt}"
AIRY_REPO_URL="${AIRY_REPO_URL:-https://atomgit.com/openairymax/airymaxhub.git}"
AIRY_VERSION="${AIRY_VERSION:-main}"
AIRY_BUILD_JOBS="${AIRY_BUILD_JOBS:-$(nproc 2>/dev/null || echo 4)}"
AIRY_SRC_DIR="${AIRY_HOME}/src/airymaxhub"

# 15 个 daemon 完整清单（安装后逐一校验）
EXPECTED_DAEMONS="monit_d observe_d info_d notify_d sched_d channel_d mem_d
                  llm_d tool_d hook_d plugin_d agent_d a2a_d market_d gateway_d"

# ─── 依赖检测 ──────────────────────────────────────────────────────────
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
    require_cmd git
    require_cmd curl
    if [ "${AIRY_NO_BUILD:-}" = "1" ]; then return 0; fi
    require_cmd cmake
    require_cmd make
    if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v cc >/dev/null 2>&1; then
        log_err "未找到 C 编译器（gcc/clang/cc）"
        exit 1
    fi
    # 运行时依赖库（非强制，缺失时功能受限但不阻塞安装）
    for lib in libcurl sqlite3; do
        if ! pkg-config --exists "$lib" 2>/dev/null; then
            log_warn "未检测到 ${lib} 开发库，部分功能受限（建议安装 lib${lib}-dev）"
        fi
    done
}

# ─── 创建 AIRY_HOME 目录骨架 ───────────────────────────────────────────
init_home() {
    mkdir -p "${AIRY_HOME}"/bin "${AIRY_HOME}"/lib "${AIRY_HOME}"/run \
             "${AIRY_HOME}"/logs "${AIRY_HOME}"/config "${AIRY_HOME}"/data \
             "${AIRY_HOME}"/tmp "${AIRY_HOME}"/cache
    chmod 700 "${AIRY_HOME}/config" 2>/dev/null || true
    log_ok "AIRY_HOME 就绪: ${AIRY_HOME}"
}

# ─── 方式 A：release 二进制 tarball（优先） ─────────────────────────────
install_binary() {
    local url="$1"
    local tarball="${AIRY_HOME}/tmp/agentrt-${AIRY_VERSION}.tar.gz"
    log_info "下载预编译包: ${url}"
    if ! curl -fsSL --max-time 600 -o "${tarball}" "${url}"; then
        log_warn "release 下载失败，回退源码构建"
        rm -f "${tarball}"
        return 1
    fi
    tar -xzf "${tarball}" -C "${AIRY_HOME}/tmp"
    # tarball 顶层目录假设为 agentrt-<ver>，将其 bin 合并到 AIRY_HOME
    local extracted
    extracted="$(find "${AIRY_HOME}/tmp" -maxdepth 1 -type d -name 'agentrt-*' | head -1)"
    [ -n "$extracted" ] || { log_warn "release 包结构异常，回退源码构建"; return 1; }
    cp -f "${extracted}"/bin/* "${AIRY_HOME}/bin/" 2>/dev/null || true
    cp -f "${extracted}"/lib/* "${AIRY_HOME}/lib/" 2>/dev/null || true
    log_ok "预编译包安装完成"
    return 0
}

# ─── 方式 B：git 拉取 + 源码构建 ───────────────────────────────────────
build_from_source() {
    if [ ! -d "${AIRY_SRC_DIR}/.git" ]; then
        log_info "git 拉取 airymaxhub（${AIRY_REPO_URL}）…"
        mkdir -p "$(dirname "${AIRY_SRC_DIR}")"
        git clone --recursive --depth 1 -b "${AIRY_VERSION}" "${AIRY_REPO_URL}" "${AIRY_SRC_DIR}" \
            || { log_err "git 拉取失败"; exit 1; }
    else
        log_info "airymaxhub 源码已存在，拉取更新…"
        git -C "${AIRY_SRC_DIR}" fetch --all --tags --depth 1 >/dev/null 2>&1 || true
        git -C "${AIRY_SRC_DIR}" checkout "${AIRY_VERSION}" 2>/dev/null || true
        git -C "${AIRY_SRC_DIR}" submodule update --init --recursive
    fi
    log_ok "源码就绪: ${AIRY_SRC_DIR}"

    if [ "${AIRY_NO_BUILD:-}" = "1" ]; then
        log_info "AIRY_NO_BUILD=1，跳过构建"
        return 0
    fi

    local build_dir="${AIRY_HOME}/build"
    log_info "cmake 配置（BUILD_TESTS=OFF，安装前缀 ${AIRY_HOME}）…"
    cmake -S "${AIRY_SRC_DIR}/agentrt" -B "${build_dir}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTS=OFF \
        -DCMAKE_INSTALL_PREFIX="${AIRY_HOME}" \
        || { log_err "cmake 配置失败"; exit 1; }

    log_info "构建（-j${AIRY_BUILD_JOBS}）…"
    cmake --build "${build_dir}" -j"${AIRY_BUILD_JOBS}" \
        || { log_err "构建失败"; exit 1; }

    log_info "安装到 ${AIRY_HOME}…"
    cmake --install "${build_dir}" || true
    # 兜底：将构建产物复制到 AIRY_HOME/bin（install 规则覆盖不到的 daemon）
    if [ -d "${build_dir}/bin" ]; then
        cp -f "${build_dir}"/bin/* "${AIRY_HOME}/bin/" 2>/dev/null || true
    fi
    log_ok "源码构建安装完成"

    # Python 运行时依赖 → lib/（ecosystem 与 sdk）
    install_python_deps
}

# ─── Python 依赖安装 → lib/ ────────────────────────────────────────────
install_python_deps() {
    log_info "安装 Python 依赖到 ${AIRY_HOME}/lib …"
    local pkg
    for pkg in airymax_agents airymax_agents_rs; do
        [ -d "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" ] || { log_warn "源码包缺失，跳过: ecosystem/agents/${pkg}"; continue; }
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude 'tests' --exclude '__pycache__' --exclude '.git' \
                  --exclude 'examples' "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" "${AIRY_HOME}/lib/"
        else
            cp -r "${AIRY_SRC_DIR}/ecosystem/agents/${pkg}" "${AIRY_HOME}/lib/"
        fi
    done
    for pkg in openlab markets contrib app; do
        [ -d "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" ] || { log_warn "源码包缺失，跳过: ecosystem/openlab/${pkg}"; continue; }
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude 'tests' --exclude '__pycache__' --exclude '.git' \
                  --exclude 'examples' "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" "${AIRY_HOME}/lib/"
        else
            cp -r "${AIRY_SRC_DIR}/ecosystem/openlab/${pkg}" "${AIRY_HOME}/lib/"
        fi
    done
    [ -d "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" ] || { log_warn "源码包缺失，跳过: sdk/sdk-python/agentrt"; return; }
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude 'tests' --exclude '__pycache__' --exclude '.git' \
              "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" "${AIRY_HOME}/lib/"
    else
        cp -r "${AIRY_SRC_DIR}/sdk/sdk-python/agentrt" "${AIRY_HOME}/lib/"
    fi
    if command -v python3 >/dev/null 2>&1; then
        if PYTHONPATH="${AIRY_HOME}/lib" python3 -c "import agentrt, airymax_agents, openlab, markets" 2>/dev/null; then
            log_ok "Python 依赖可导入 (agentrt/airymax_agents/openlab/markets)"
        else
            log_warn "lib/ 导入校验失败（检查源码包结构）"
        fi
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
            log_warn "未找到 secrets.env 模板（devtools 子仓缺失？），跳过"
        fi
    else
        log_ok "secrets.env 已存在，跳过"
    fi
}

# ─── 固化安装位置 + 生成运行环境 ───────────────────────────────────────
finalize_install() {
    {
        echo "# AgentRT 安装信息（由 install.sh 生成，勿手改）"
        echo "AIRY_HOME=${AIRY_HOME}"
        echo "AIRY_VERSION=${AIRY_VERSION}"
        echo "INSTALLED_AT=$(date -Is 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')"
    } > "${AIRY_HOME}/config/install.env"
    chmod 600 "${AIRY_HOME}/config/install.env"

    cat > "${AIRY_HOME}/bin/agentrt-env.sh" <<EOF
#!/bin/sh
# AgentRT 运行环境（由 install.sh 生成，source 使用）
# 用法: . \${AIRY_HOME:-${AIRY_HOME}}/bin/agentrt-env.sh
export AIRY_HOME="${AIRY_HOME}"
export AIRY_RUNTIME_DIR="\${AIRY_RUNTIME_DIR:-\$AIRY_HOME/run}"
export AIRY_LOG_DIR="\${AIRY_LOG_DIR:-\$AIRY_HOME/logs}"
export AIRY_CONFIG_DIR="\${AIRY_CONFIG_DIR:-\$AIRY_HOME/config}"
export AIRY_BIN_DIR="\${AIRY_BIN_DIR:-\$AIRY_HOME/bin}"
export AIRY_LIB_DIR="\${AIRY_LIB_DIR:-\$AIRY_HOME/lib}"
export PATH="\${AIRY_HOME}/bin:\$PATH"
EOF
    chmod 700 "${AIRY_HOME}/bin/agentrt-env.sh"
    log_ok "安装位置已固化: install.env + agentrt-env.sh"
}

# ─── 15 daemon 完整性校验 ──────────────────────────────────────────────
verify_daemons() {
    local missing=""
    for d in ${EXPECTED_DAEMONS}; do
        if [ ! -x "${AIRY_HOME}/bin/${d}" ]; then
            missing="${missing} ${d}"
        fi
    done
    if [ -n "${missing}" ]; then
        log_warn "daemon 校验未全通过，缺失:${missing}（可能是 release 包未含全部 daemon，或构建模式受限）"
    else
        log_ok "15 个 daemon 全部就位"
    fi
}

# ─── 版本信息 ──────────────────────────────────────────────────────────
print_banner() {
    cat <<EOF
${C_CYAN}
  ┌─────────────────────────────────────────────────────┐
  │        Airymax AgentRT Runtime Platform             │
  │        运行时 · 框架 · 超级智能体 一体化              │
  └─────────────────────────────────────────────────────┘
${C_NC}
EOF
}

print_summary() {
    cat <<EOF

安装位置:   ${AIRY_HOME}
可执行文件: ${AIRY_HOME}/bin/
配置文件:   ${AIRY_HOME}/config/agentrt.yaml
安装固化:   ${AIRY_HOME}/config/install.env
运行环境:   ${AIRY_HOME}/bin/agentrt-env.sh

快速开始:
  1. 配置运行环境（source 后获得完整 PATH 与目录变量）:
     . ${AIRY_HOME}/bin/agentrt-env.sh
  2. 配置 LLM 提供方:
     ${AIRY_HOME}/bin/agentrt llm add --provider <openai|anthropic|...>
  3. 启动运行时网关（所有 daemon 的统一入口）:
     ${AIRY_HOME}/bin/gateway_d &
  4. 运行你的第一个 Agent:
     ${AIRY_HOME}/bin/agentrt run "帮我分析这份文档"

卸载（干净彻底，所有产物收敛于 AIRY_HOME）:
     rm -rf "${AIRY_HOME}"
EOF
}

# ─── 主流程 ────────────────────────────────────────────────────────────
main() {
    print_banner
    log_info "Airymax AgentRT 安装程序"
    log_info "AIRY_HOME = ${AIRY_HOME}"
    log_info "版本     = ${AIRY_VERSION}"

    check_toolchain
    init_home

    # 优先 release 二进制；无 release 或失败时走源码构建
    local installed=1
    if [ -n "${AIRY_RELEASE_URL:-}" ]; then
        install_binary "${AIRY_RELEASE_URL}" && installed=0
    fi
    if [ "${installed}" -ne 0 ]; then
        log_info "进入源码构建模式（git 拉取 + cmake 构建）"
        build_from_source
        init_secrets
    fi

    finalize_install
    verify_daemons
    print_summary
    log_ok "安装完成"
}

main "$@"
