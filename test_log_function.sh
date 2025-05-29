#!/bin/bash
# 测试脚本：验证 clash log 功能

echo "=== Clash Log 功能测试 ==="
echo ""

# 确保加载最新的脚本
source /opt/clash/script/common.sh
source /opt/clash/script/clashctl.sh

echo "1. 测试帮助信息:"
echo "   执行: clash log --help"
clash log --help
echo ""

echo "2. 测试基本日志查看 (默认50行):"
echo "   执行: clash log | head -3"
clash log | head -3
echo "   ..."
echo ""

echo "3. 测试指定行数:"
echo "   执行: clash log -n 5"
clash log -n 5
echo ""

echo "4. 测试长参数格式:"
echo "   执行: clash log --lines 3"
clash log --lines 3
echo ""

echo "5. 测试错误参数:"
echo "   执行: clash log -n abc"
clash log -n abc 2>&1 || echo "   ✅ 正确处理了错误参数"
echo ""

echo "6. 测试未知参数:"
echo "   执行: clash log --unknown"
clash log --unknown 2>&1 || echo "   ✅ 正确处理了未知参数"
echo ""

echo "7. 测试服务状态检查:"
if systemctl is-active mihomo >/dev/null 2>&1; then
    echo "   ✅ mihomo 服务正在运行"
else
    echo "   ❌ mihomo 服务未运行"
fi
echo ""

echo "8. 测试命令可用性:"
if command -v clash >/dev/null 2>&1; then
    echo "   ✅ clash 命令可用"
    echo "   命令位置: $(which clash)"
else
    echo "   ❌ clash 命令不可用"
fi
echo ""

echo "9. 测试在新 bash 环境中的可用性:"
if bash -c 'source /opt/clash/script/clashctl.sh && clash log --help' >/dev/null 2>&1; then
    echo "   ✅ 新 bash 环境中 clash log 功能可用"
else
    echo "   ❌ 新 bash 环境中 clash log 功能不可用"
fi
echo ""

echo "=== 测试完成 ==="
echo ""
echo "可用的 clash log 命令："
echo "  clash log                    # 显示最后50行日志"
echo "  clash log -n 100            # 显示最后100行日志"
echo "  clash log --lines 20        # 显示最后20行日志"
echo "  clash log -f                # 实时跟踪日志"
echo "  clash log -f -n 10          # 显示最后10行并实时跟踪"
echo "  clash log --help            # 显示帮助信息"
