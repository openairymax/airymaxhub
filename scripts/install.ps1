# ============================================================================
# Airymax AgentRT 一键安装脚本 (Windows PowerShell)
#
# 用法：
#   powershell -ExecutionPolicy Bypass -Command "irm https://raw.atomgit.com/openairymax/airymaxhub/raw/main/scripts/install.ps1 | iex"
#
# 安装策略（两级，与 install.sh 对齐）：
#   1. 二进制优先：AIRY_RELEASE_URL 指向预编译 zip 时直接下载解压。
#   2. 源码构建回退：git 拉取 agentrt 管理仓 + cmake + MSVC/LLVM 构建。
#
# 路径体系（与 platform.h AIRY_HOME 一致）：
#   $AIRY_HOME            = ${AIRY_HOME:-~/.airymaxrt}
#   $AIRY_HOME\bin / lib / run / logs / config / data / tmp / cache
#
# 环境变量：
#   AIRY_HOME        — 安装根目录（默认 ~/.airymaxrt）
#   AIRY_VERSION     — 版本 tag（默认 main）
#   AIRY_REPO_URL    — agentrt 管理仓（默认 https://atomgit.com/openairymax/agentrt.git）
#   AIRY_RELEASE_URL — 预编译 zip 直链（覆盖二进制路径）
#
# 卸载：Remove-Item -Recurse -Force $env:AIRY_HOME 即干净卸载。
# ============================================================================

$ErrorActionPreference = "Stop"

# ─── 参数 ────────────────────────────────────────────────────────────────
$AIRY_HOME    = if ($env:AIRY_HOME)    { $env:AIRY_HOME }    else { Join-Path $HOME ".airymaxrt" }
$AIRY_VERSION = if ($env:AIRY_VERSION) { $env:AIRY_VERSION } else { "main" }
$AIRY_REPO_URL = if ($env:AIRY_REPO_URL) { $env:AIRY_REPO_URL } else { "https://atomgit.com/openairymax/agentrt.git" }

function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-OK    { Write-Host "[ OK ] $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err   { Write-Host "[FAIL] $args" -ForegroundColor Red }

function Require-Cmd {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Err "缺少必要工具: $Name"
        if ($Name -eq "git")    { Write-Warn "请安装 Git for Windows: https://git-scm.com/download/win" }
        if ($Name -eq "cmake")  { Write-Warn "请安装 CMake ≥3.20: https://cmake.org/download/" }
        if ($Name -eq "curl")   { Write-Warn "Windows 10+ 自带 curl.exe" }
        throw "缺少 $Name"
    }
}

function Init-Home {
    foreach ($sub in @("bin","lib","run","logs","config","data","tmp","cache")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $AIRY_HOME $sub) | Out-Null
    }
    Write-OK "AIRY_HOME 就绪: $AIRY_HOME"
}

function Install-Binary {
    param([string]$Url)
    $zip = Join-Path $AIRY_HOME "tmp\agentrt-$AIRY_VERSION.zip"
    Write-Info "下载预编译包: $Url"
    curl.exe -fsSL --max-time 600 -o $zip $Url
    if ($LASTEXITCODE -ne 0) { Write-Warn "release 下载失败，回退源码构建"; return $false }
    Expand-Archive -Path $zip -DestinationPath (Join-Path $AIRY_HOME "tmp") -Force
    Get-ChildItem (Join-Path $AIRY_HOME "tmp") -Directory | Where-Object { $_.Name -like "agentrt-*" } | ForEach-Object {
        Get-ChildItem (Join-Path $_.FullName "bin") -ErrorAction SilentlyContinue | Copy-Item -Destination (Join-Path $AIRY_HOME "bin") -Force
        Get-ChildItem (Join-Path $_.FullName "lib") -ErrorAction SilentlyContinue | Copy-Item -Destination (Join-Path $AIRY_HOME "lib") -Force
    }
    Write-OK "预编译包安装完成"
    return $true
}

function Build-FromSource {
    $srcDir = Join-Path $AIRY_HOME "src\agentrt"
    if (-not (Test-Path (Join-Path $srcDir ".git"))) {
        Write-Info "git 拉取 agentrt（$AIRY_REPO_URL）…"
        git clone --recursive --depth 1 -b $AIRY_VERSION $AIRY_REPO_URL $srcDir
        if ($LASTEXITCODE -ne 0) { Write-Err "git 拉取失败"; throw "git clone failed" }
    } else {
        Write-Info "agentrt 源码已存在，拉取更新…"
        git -C $srcDir fetch --all --tags --depth 1
        git -C $srcDir checkout $AIRY_VERSION
        git -C $srcDir submodule update --init --recursive
    }
    Write-OK "源码就绪: $srcDir"

    $buildDir = Join-Path $AIRY_HOME "build"
    Write-Info "cmake 配置…"
    cmake -S $srcDir -B $buildDir -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$AIRY_HOME
    if ($LASTEXITCODE -ne 0) { Write-Err "cmake 配置失败"; throw "cmake configure failed" }

    Write-Info "构建…"
    cmake --build $buildDir --config Release --parallel
    if ($LASTEXITCODE -ne 0) { Write-Err "构建失败"; throw "build failed" }

    Write-Info "安装到 $AIRY_HOME…"
    cmake --install $buildDir --config Release
    $binDir = Join-Path $buildDir "bin\Release"
    if (Test-Path $binDir) { Copy-Item (Join-Path $binDir "*") (Join-Path $AIRY_HOME "bin") -Recurse -Force -ErrorAction SilentlyContinue }
    Write-OK "源码构建安装完成"
}

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │        Airymax AgentRT Runtime Platform             │" -ForegroundColor Cyan
Write-Host "  │        运行时 · 框架 · 超级智能体 一体化              │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

Write-Info "Airymax AgentRT 安装程序"
Write-Info "AIRY_HOME = $AIRY_HOME"
Write-Info "版本     = $AIRY_VERSION"

Require-Cmd "git"
Require-Cmd "curl"
Init-Home

$installed = $false
if ($env:AIRY_RELEASE_URL) {
    $installed = Install-Binary $env:AIRY_RELEASE_URL
}
if (-not $installed) {
    Write-Info "进入源码构建模式（git 拉取 + cmake 构建）"
    Build-FromSource
}

Write-Host ""
Write-Host "安装位置:   $AIRY_HOME" -ForegroundColor Green
Write-Host "可执行文件: $AIRY_HOME\bin\" -ForegroundColor Green
Write-Host "快速开始:   Start-Process `"$AIRY_HOME\bin\gateway_d`" (运行时网关)" -ForegroundColor Green
Write-Host "            `$AIRY_HOME\bin\agentrt run `"帮我分析这份文档`"" -ForegroundColor Green
Write-Host "卸载:       Remove-Item -Recurse -Force `"$AIRY_HOME`"" -ForegroundColor Green
Write-OK "安装完成"
