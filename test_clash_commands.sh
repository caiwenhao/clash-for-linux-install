#!/bin/bash
# 测试脚本：验证 clash 命令在新终端中是否可用

echo "=== Clash 命令可用性测试 ==="
echo ""

# 测试 1: 检查 PATH 中是否包含 clash 二进制目录
echo "1. 检查 PATH 环境变量:"
if echo "$PATH" | grep -q "/opt/clash/bin"; then
    echo "   ✅ PATH 中包含 /opt/clash/bin"
else
    echo "   ❌ PATH 中不包含 /opt/clash/bin"
fi
echo ""

# 测试 2: 检查全局命令是否存在
echo "2. 检查全局命令文件:"
if [ -f "/usr/local/bin/clash" ]; then
    echo "   ✅ /usr/local/bin/clash 存在"
else
    echo "   ❌ /usr/local/bin/clash 不存在"
fi

if [ -f "/usr/local/bin/mihomo" ]; then
    echo "   ✅ /usr/local/bin/mihomo 存在"
else
    echo "   ❌ /usr/local/bin/mihomo 不存在"
fi
echo ""

# 测试 3: 检查系统级配置文件
echo "3. 检查系统级配置:"
if [ -f "/etc/profile.d/clash.sh" ]; then
    echo "   ✅ /etc/profile.d/clash.sh 存在"
else
    echo "   ❌ /etc/profile.d/clash.sh 不存在"
fi
echo ""

# 测试 4: 检查用户配置文件
echo "4. 检查用户配置文件:"
if [ -f "$HOME/.bashrc" ] && grep -q "/opt/clash" "$HOME/.bashrc"; then
    echo "   ✅ ~/.bashrc 中包含 clash 配置"
else
    echo "   ❌ ~/.bashrc 中不包含 clash 配置"
fi

if [ -f "$HOME/.zshrc" ] && grep -q "/opt/clash" "$HOME/.zshrc"; then
    echo "   ✅ ~/.zshrc 中包含 clash 配置"
else
    echo "   ❌ ~/.zshrc 中不包含 clash 配置"
fi
echo ""

# 测试 5: 尝试执行 clash 命令
echo "5. 测试命令执行:"
if command -v clash >/dev/null 2>&1; then
    echo "   ✅ clash 命令可用"
    echo "   命令位置: $(which clash)"
else
    echo "   ❌ clash 命令不可用"
fi

if command -v mihomo >/dev/null 2>&1; then
    echo "   ✅ mihomo 命令可用"
    echo "   命令位置: $(which mihomo)"
else
    echo "   ❌ mihomo 命令不可用"
fi
echo ""

# 测试 6: 模拟新终端环境
echo "6. 模拟新终端环境测试:"
echo "   执行: bash -c 'command -v clash'"
if bash -c 'command -v clash' >/dev/null 2>&1; then
    echo "   ✅ 新 bash 终端中 clash 命令可用"
else
    echo "   ❌ 新 bash 终端中 clash 命令不可用"
fi

echo "   执行: zsh -c 'command -v clash'"
if zsh -c 'command -v clash' >/dev/null 2>&1; then
    echo "   ✅ 新 zsh 终端中 clash 命令可用"
else
    echo "   ❌ 新 zsh 终端中 clash 命令不可用"
fi
echo ""

echo "=== 测试完成 ==="
echo ""
echo "如果发现问题，请尝试以下解决方案："
echo "1. 重新打开终端窗口"
echo "2. 执行: source ~/.bashrc 或 source ~/.zshrc"
echo "3. 执行: source /etc/profile.d/clash.sh"
echo "4. 检查是否有权限问题"
