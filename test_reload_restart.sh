#!/bin/bash

# 测试 clash reload 和 restart 功能的脚本

echo "=== Clash Reload & Restart 功能测试 ==="
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

echo "2. 测试 clash restart 命令:"
echo "---------------------------"
echo "检查 restart 命令是否在帮助中显示:"
if clash 2>&1 | grep -q "restart"; then
    echo "   ✅ 帮助信息已包含 restart 命令"
else
    echo "   ❌ 帮助信息未包含 restart 命令"
fi
echo ""

echo "3. 测试函数定义:"
echo "----------------"
if type clashreload >/dev/null 2>&1; then
    echo "   ✅ clashreload 函数已定义"
else
    echo "   ❌ clashreload 函数未定义"
fi

if type clashrestart >/dev/null 2>&1; then
    echo "   ✅ clashrestart 函数已定义"
else
    echo "   ❌ clashrestart 函数未定义"
fi
echo ""

echo "4. 测试配置文件检查:"
echo "---------------------"
if [[ -f "$CLASH_CONFIG_RUNTIME" ]]; then
    echo "   ✅ 配置文件存在: $CLASH_CONFIG_RUNTIME"
else
    echo "   ❌ 配置文件不存在: $CLASH_CONFIG_RUNTIME"
fi
echo ""

echo "5. 测试服务状态:"
echo "----------------"
if systemctl is-active "$BIN_KERNEL_NAME" >/dev/null 2>&1; then
    echo "   ✅ $BIN_KERNEL_NAME 服务正在运行"
else
    echo "   ❌ $BIN_KERNEL_NAME 服务未运行"
fi
echo ""

echo "6. 测试命令可用性:"
echo "-------------------"
if command -v clash >/dev/null 2>&1; then
    echo "   ✅ clash 命令可用"
    echo "   命令位置: $(which clash)"
else
    echo "   ❌ clash 命令不可用"
fi
echo ""

echo "7. 测试帮助信息完整性:"
echo "----------------------"
echo "检查 clash 命令帮助中是否包含新命令:"
help_output=$(clash 2>&1)
if echo "$help_output" | grep -q "reload"; then
    echo "   ✅ 帮助信息包含 reload 命令"
else
    echo "   ❌ 帮助信息不包含 reload 命令"
fi

if echo "$help_output" | grep -q "restart"; then
    echo "   ✅ 帮助信息包含 restart 命令"
else
    echo "   ❌ 帮助信息不包含 restart 命令"
fi
echo ""

echo "8. 测试在新 bash 环境中的可用性:"
echo "--------------------------------"
if bash -c 'source /opt/clash/script/clashctl.sh 2>/dev/null && clash reload --help' >/dev/null 2>&1; then
    echo "   ✅ 新 bash 环境中 clash reload 功能可用"
else
    echo "   ❌ 新 bash 环境中 clash reload 功能不可用"
fi
echo ""

echo "=== 测试完成 ==="
echo ""
echo "可用的新命令:"
echo "  clash reload --help    # 查看重载帮助"
echo "  clash reload           # 重载配置文件"
echo "  clash restart          # 重启服务"
echo ""
echo "注意: 实际执行 reload 和 restart 命令会影响正在运行的服务"
