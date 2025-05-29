#!/bin/bash

# 测试 clash reload 功能的脚本

echo "=== Clash Reload 功能测试 ==="
echo ""

# 设置测试环境
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/script/common.sh" 2>/dev/null || {
    echo "❌ 无法加载 common.sh"
    exit 1
}
source "$SCRIPT_DIR/script/clashctl.sh" 2>/dev/null || {
    echo "❌ 无法加载 clashctl.sh"
    exit 1
}

echo "1. 测试 clash reload --help:"
echo "----------------------------"
clash reload --help
echo ""

echo "2. 测试命令可用性:"
echo "-------------------"
if command -v clash >/dev/null 2>&1; then
    echo "   ✅ clash 命令可用"
    echo "   命令位置: $(which clash)"
else
    echo "   ❌ clash 命令不可用"
fi
echo ""

echo "3. 测试配置文件检查:"
echo "---------------------"
if [[ -f "$CLASH_CONFIG_RUNTIME" ]]; then
    echo "   ✅ 配置文件存在: $CLASH_CONFIG_RUNTIME"
else
    echo "   ❌ 配置文件不存在: $CLASH_CONFIG_RUNTIME"
fi
echo ""

echo "4. 测试服务状态:"
echo "----------------"
if systemctl is-active "$BIN_KERNEL_NAME" >/dev/null 2>&1; then
    echo "   ✅ $BIN_KERNEL_NAME 服务正在运行"
else
    echo "   ❌ $BIN_KERNEL_NAME 服务未运行"
fi
echo ""

echo "5. 测试 API 端口获取:"
echo "---------------------"
_get_ui_port 2>/dev/null
if [[ -n "$UI_PORT" ]]; then
    echo "   ✅ API 端口: $UI_PORT"
    
    # 测试 API 连接
    if curl -s "http://127.0.0.1:${UI_PORT}/version" >/dev/null 2>&1; then
        echo "   ✅ API 连接正常"
    else
        echo "   ⚠️ API 连接失败"
    fi
else
    echo "   ❌ 无法获取 API 端口"
fi
echo ""

echo "6. 测试配置验证功能:"
echo "--------------------"
if [[ -f "$CLASH_CONFIG_RUNTIME" ]]; then
    if _valid_config "$CLASH_CONFIG_RUNTIME" 2>/dev/null; then
        echo "   ✅ 配置文件验证通过"
    else
        echo "   ❌ 配置文件验证失败"
    fi
else
    echo "   ⚠️ 配置文件不存在，跳过验证"
fi
echo ""

echo "7. 测试 reload 函数定义:"
echo "------------------------"
if type clashreload >/dev/null 2>&1; then
    echo "   ✅ clashreload 函数已定义"
else
    echo "   ❌ clashreload 函数未定义"
fi
echo ""

echo "8. 测试帮助信息更新:"
echo "--------------------"
echo "检查 clash 命令帮助中是否包含 reload:"
if clash 2>&1 | grep -q "reload"; then
    echo "   ✅ 帮助信息已包含 reload 命令"
else
    echo "   ❌ 帮助信息未包含 reload 命令"
fi
echo ""

echo "9. 测试在新 bash 环境中的可用性:"
echo "--------------------------------"
if bash -c 'source /opt/clash/script/clashctl.sh && clash reload --help' >/dev/null 2>&1; then
    echo "   ✅ 新 bash 环境中 clash reload 功能可用"
else
    echo "   ❌ 新 bash 环境中 clash reload 功能不可用"
fi
echo ""

echo "=== 测试完成 ==="
echo ""
echo "如果所有测试都通过，可以尝试运行:"
echo "  clash reload --help    # 查看帮助"
echo "  clash reload           # 热重载配置"
echo "  clash reload -f        # 强制重启服务"
