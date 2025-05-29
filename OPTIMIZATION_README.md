# Clash 安装脚本优化说明

## 问题描述

原始安装脚本存在一个问题：安装完毕后，重新进入终端时 `clash` 命令找不到。这是因为：

1. **PATH 环境变量未设置**：脚本没有将 clash 二进制文件路径添加到 PATH 环境变量中
2. **依赖函数加载**：clash 命令实际上是 shell 函数，需要通过 source 加载脚本才能使用
3. **缺少全局访问机制**：没有创建系统级的命令访问方式

## 优化方案

### 1. 多层次的环境变量设置

- **用户级配置**：在用户的 shell 配置文件（~/.bashrc, ~/.zshrc）中添加 PATH 设置
- **系统级配置**：创建 `/etc/profile.d/clash.sh` 确保所有用户都能使用
- **避免重复添加**：检查配置是否已存在，避免重复添加相同内容

### 2. 全局命令脚本

创建 `/usr/local/bin/clash` 和 `/usr/local/bin/mihomo` 全局命令脚本：
- 这些脚本会自动加载必要的函数定义
- 即使在没有加载 shell 配置的环境中也能正常工作
- 提供错误处理和友好的错误信息

### 3. 改进的卸载机制

优化 `_set_rc unset` 函数，确保卸载时能够：
- 清理用户配置文件中的相关设置
- 删除系统级配置文件
- 删除全局命令脚本

### 4. 用户友好的安装提示

在安装完成后提供清晰的使用指导：
- 告知用户如何在新终端中使用命令
- 提供多种环境变量加载方式
- 给出具体的操作步骤

## 技术实现

### 修改的文件

1. **script/common.sh**
   - 优化 `_set_rc()` 函数
   - 新增 `_create_global_commands()` 函数

2. **install.sh**
   - 添加安装完成后的用户提示

### 新增的功能

1. **PATH 环境变量设置**
   ```bash
   export PATH="/opt/clash/bin:$PATH"
   ```

2. **系统级配置文件** (`/etc/profile.d/clash.sh`)
   ```bash
   #!/bin/bash
   export PATH="/opt/clash/bin:$PATH"
   # 加载 clash 函数并自动检查代理状态
   ```

3. **全局命令脚本** (`/usr/local/bin/clash`, `/usr/local/bin/mihomo`)
   - 自动加载必要的脚本文件
   - 提供错误处理
   - 调用相应的 shell 函数

## 使用方法

### 安装后的使用

安装完成后，用户可以通过以下方式使用 clash 命令：

1. **重新打开终端**（推荐）
2. **手动加载环境变量**：
   ```bash
   source ~/.bashrc    # bash 用户
   source ~/.zshrc     # zsh 用户
   source /etc/profile.d/clash.sh  # 任何 shell
   ```

### 验证安装

运行测试脚本验证安装是否成功：
```bash
bash test_clash_commands.sh
```

### 常用命令

```bash
clash on          # 开启代理
clash off         # 关闭代理
clash ui          # 显示 Web 控制台地址
clash status      # 查看服务状态
clash update      # 更新订阅
```

## 兼容性

- ✅ 支持 bash 和 zsh
- ✅ 支持多用户环境
- ✅ 向后兼容原有功能
- ✅ 支持 sudo 安装
- ✅ 支持系统级和用户级配置

## 故障排除

如果 clash 命令仍然不可用：

1. **检查安装是否完整**：
   ```bash
   ls -la /opt/clash/bin/
   ls -la /usr/local/bin/clash
   ```

2. **检查权限**：
   ```bash
   ls -la /usr/local/bin/clash
   ls -la /etc/profile.d/clash.sh
   ```

3. **手动加载配置**：
   ```bash
   source /etc/profile.d/clash.sh
   ```

4. **检查 PATH**：
   ```bash
   echo $PATH | grep clash
   ```

## 更新日志

- 添加多层次环境变量设置机制
- 创建全局命令脚本
- 改进卸载清理功能
- 添加用户友好的安装提示
- 提供测试脚本验证安装结果
