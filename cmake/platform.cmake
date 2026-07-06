# =============================================================================
# platform.cmake — Airymax 平台检测与特性宏配置模块
# 版本：1.0.0
# 创建：2026-07-06
# 归属：airymaxhub 伞仓直属（非 submodule）
#
# 设计目标：
#   统一检测目标平台（Linux/macOS/Windows/MSVC/GCC/Clang），并设置对应的
#   POSIX 特性测试宏、平台定义宏、编译器特性变量。所有平台相关逻辑集中
#   在此模块，避免在 CMakeLists.txt 中散落 if(UNIX)/if(APPLE)/if(MSVC) 判断。
#
#   符合 Airymax 跨 Linux/macOS/Windows 硬约束（用户态运行时，通过 libc/POSIX
#   跨平台，禁止内核态化）。
#
# 使用方式（在 CMakeLists.txt 中）:
#   list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../../cmake")
#   include(platform)
#   agentrt_detect_platform()
# =============================================================================

include_guard(GLOBAL)

# =============================================================================
# agentrt_detect_platform — 检测平台并设置特性宏
# 设置以下变量（PARENT_SCOPE）:
#   AGENTRT_PLATFORM_LINUX / AGENTRT_PLATFORM_MACOS / AGENTRT_PLATFORM_WINDOWS
#   AGENTRT_COMPILER_GCC / AGENTRT_COMPILER_CLANG / AGENTRT_COMPILER_MSVC
#   AGENTRT_PLATFORM_NAME — 人类可读的平台名
# 同时调用 add_compile_definitions 设置 POSIX 特性宏
# =============================================================================
function(agentrt_detect_platform)
    # ---- 平台检测 ----
    set(AGENTRT_PLATFORM_LINUX OFF PARENT_SCOPE)
    set(AGENTRT_PLATFORM_MACOS OFF PARENT_SCOPE)
    set(AGENTRT_PLATFORM_WINDOWS OFF PARENT_SCOPE)

    if(UNIX AND NOT APPLE)
        set(AGENTRT_PLATFORM_LINUX ON PARENT_SCOPE)
        set(AGENTRT_PLATFORM_NAME "Linux" PARENT_SCOPE)
    elseif(APPLE)
        set(AGENTRT_PLATFORM_MACOS ON PARENT_SCOPE)
        set(AGENTRT_PLATFORM_NAME "macOS" PARENT_SCOPE)
    elseif(WIN32)
        set(AGENTRT_PLATFORM_WINDOWS ON PARENT_SCOPE)
        set(AGENTRT_PLATFORM_NAME "Windows" PARENT_SCOPE)
    else()
        set(AGENTRT_PLATFORM_NAME "Unknown" PARENT_SCOPE)
    endif()

    # ---- 编译器检测 ----
    set(AGENTRT_COMPILER_GCC OFF PARENT_SCOPE)
    set(AGENTRT_COMPILER_CLANG OFF PARENT_SCOPE)
    set(AGENTRT_COMPILER_MSVC OFF PARENT_SCOPE)

    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set(AGENTRT_COMPILER_GCC ON PARENT_SCOPE)
    elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
        set(AGENTRT_COMPILER_CLANG ON PARENT_SCOPE)
    elseif(MSVC)
        set(AGENTRT_COMPILER_MSVC ON PARENT_SCOPE)
    endif()

    # ---- POSIX 特性测试宏 ----
    # Airymax 跨 Linux/macOS/Windows 硬约束：用户态运行时，通过 libc/POSIX 跨平台
    if(UNIX AND NOT APPLE)
        add_compile_definitions(
            _POSIX_C_SOURCE=200809L
            _XOPEN_SOURCE=700
            _GNU_SOURCE
        )
        message(STATUS "POSIX feature test macros enabled for Linux")
    elseif(APPLE)
        add_compile_definitions(
            _POSIX_C_SOURCE=200112L
            _DARWIN_C_SOURCE
        )
        message(STATUS "POSIX feature test macros enabled for macOS")
    endif()
endfunction()

# =============================================================================
# agentrt_print_platform_info — 打印平台信息摘要
# =============================================================================
function(agentrt_print_platform_info)
    message(STATUS "=========================================")
    message(STATUS "  Airymax Platform Detection Summary")
    message(STATUS "=========================================")
    message(STATUS "Platform:      ${CMAKE_SYSTEM_NAME} (${CMAKE_SYSTEM_PROCESSOR})")
    message(STATUS "Platform flag: ${AGENTRT_PLATFORM_NAME}")
    message(STATUS "Compiler:      ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
    if(AGENTRT_COMPILER_GCC)
        message(STATUS "Compiler flag: GCC")
    elseif(AGENTRT_COMPILER_CLANG)
        message(STATUS "Compiler flag: Clang")
    elseif(AGENTRT_COMPILER_MSVC)
        message(STATUS "Compiler flag: MSVC")
    endif()
    message(STATUS "Build type:    ${CMAKE_BUILD_TYPE}")
    message(STATUS "=========================================")
endfunction()

# =============================================================================
# agentrt_is_unix_like — 检查是否为 Unix-like 系统（Linux/macOS/BSD）
# 参数:
#   result_var — 输出变量名，设置为 ON 或 OFF
# =============================================================================
function(agentrt_is_unix_like result_var)
    if(UNIX)
        set(${result_var} ON PARENT_SCOPE)
    else()
        set(${result_var} OFF PARENT_SCOPE)
    endif()
endfunction()

# =============================================================================
# agentrt_supports_sanitizers — 检查当前编译器是否支持 sanitizers
# 参数:
#   result_var — 输出变量名，设置为 ON 或 OFF
# =============================================================================
function(agentrt_supports_sanitizers result_var)
    if(MSVC)
        set(${result_var} OFF PARENT_SCOPE)
    elseif(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
        set(${result_var} ON PARENT_SCOPE)
    else()
        set(${result_var} OFF PARENT_SCOPE)
    endif()
endfunction()
