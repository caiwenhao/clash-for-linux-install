# Clash Log 功能说明

## 功能概述

为 clash 命令新增了 `log` 功能，用于查看 mihomo/clash 服务的系统日志。该功能基于 `journalctl` 实现，提供了灵活的日志查看选项。

## 功能特性

### ✅ 已实现的功能

1. **基本日志查看**
   - 默认显示最后 50 行日志
   - 支持自定义显示行数
   - 使用 systemd journalctl 获取日志

2. **实时日志跟踪**
   - 支持 `-f/--follow` 参数实时跟踪日志
   - 类似 `tail -f` 的功能

3. **参数解析**
   - 支持短参数和长参数格式
   - 完整的参数验证和错误处理
   - 友好的帮助信息

4. **错误处理**
   - 检查服务是否存在
   - 参数验证
   - 友好的错误提示

## 使用方法

### 基本语法

```bash
clash log [OPTIONS]
```

### 可用选项

| 选项 | 长选项 | 描述 | 默认值 |
|------|--------|------|--------|
| `-f` | `--follow` | 实时跟踪日志输出 | false |
| `-n NUMBER` | `--lines NUMBER` | 显示最后 N 行日志 | 50 |
| `-h` | `--help` | 显示帮助信息 | - |

### 使用示例

#### 1. 基本日志查看
```bash
# 显示最后50行日志（默认）
clash log

# 显示最后100行日志
clash log -n 100
clash log --lines 100
```

#### 2. 实时日志跟踪
```bash
# 实时跟踪日志
clash log -f
clash log --follow

# 显示最后20行并实时跟踪
clash log -f -n 20
clash log --follow --lines 20
```

#### 3. 获取帮助
```bash
clash log -h
clash log --help
```

## 技术实现

### 核心函数

<augment_code_snippet path="script/clashctl.sh" mode="EXCERPT">
```bash
function clashlog() {
    local lines=50
    local follow=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow=true
                shift
                ;;
            -n|--lines)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    lines="$2"
                    shift 2
                else
                    _failcat "错误: -n/--lines 需要一个数字参数"
                    return 1
                fi
                ;;
            -h|--help)
                # 显示帮助信息
                return 0
                ;;
            *)
                _failcat "未知参数: $1"
                _failcat "使用 'clash log --help' 查看帮助"
                return 1
                ;;
        esac
    done
    
    # 检查服务是否存在
    if ! systemctl list-unit-files | grep -q "^${BIN_KERNEL_NAME}.service"; then
        _failcat "错误: ${BIN_KERNEL_NAME} 服务不存在"
        return 1
    fi
    
    # 构建并执行 journalctl 命令
    local cmd="sudo journalctl -u ${BIN_KERNEL_NAME}"
    
    if [[ "$follow" == "true" ]]; then
        cmd="$cmd -f"
        _okcat "🔍" "实时跟踪 ${BIN_KERNEL_NAME} 日志 (按 Ctrl+C 退出)..."
    else
        _okcat "📋" "显示 ${BIN_KERNEL_NAME} 最后 ${lines} 行日志..."
    fi
    
    cmd="$cmd -n ${lines} --no-pager"
    eval "$cmd"
}
```
</augment_code_snippet>

### 集成到主命令

在 `clashctl` 函数中添加了 `log` 命令的处理：

```bash
log)
    shift
    clashlog "$@"
    ;;
```

并更新了帮助信息：

```bash
Commands:
    on                   开启代理
    off                  关闭代理
    ui                   面板地址
    status               内核状况
    log      [-f] [-n N] 查看日志    # 新增
    tun      [on|off]    Tun 模式
    mixin    [-e|-r]     Mixin 配置
    secret   [SECRET]    Web 密钥
    update   [auto|log]  更新订阅
```

## 日志内容示例

mihomo 服务的日志通常包含以下信息：

```
May 29 14:13:28 hostname mihomo[54152]: time="2025-05-29T14:13:28.683560316+08:00" level=info msg="[TCP] 127.0.0.1:59612 --> d16.api.augmentcode.com:443 match Match using Proxy[HongKong-Public-VMess]"
```

日志格式说明：
- **时间戳**：系统时间和服务时间
- **主机名**：运行服务的主机名
- **进程信息**：mihomo[PID]
- **日志级别**：info, warning, error 等
- **连接信息**：源地址 --> 目标地址，匹配规则和使用的代理

## 故障排除

### 常见问题

1. **服务不存在错误**
   ```bash
   😾 错误: mihomo 服务不存在
   ```
   **解决方案**：检查 clash 是否正确安装，运行 `clash status` 确认服务状态

2. **权限问题**
   ```bash
   Failed to get journal access: Permission denied
   ```
   **解决方案**：确保以 root 权限运行，或用户在 systemd-journal 组中

3. **参数错误**
   ```bash
   😾 错误: -n/--lines 需要一个数字参数
   ```
   **解决方案**：确保 `-n` 参数后跟有效的数字

### 调试命令

```bash
# 检查服务状态
clash status

# 检查服务是否存在
systemctl list-unit-files | grep mihomo

# 直接使用 journalctl
sudo journalctl -u mihomo -n 10
```

## 兼容性

- ✅ 支持 mihomo 和 clash 内核
- ✅ 兼容 systemd 系统
- ✅ 支持 bash 和 zsh
- ✅ 向后兼容现有功能

## 更新日志

- **新增功能**：clash log 命令
- **支持参数**：-f/--follow, -n/--lines, -h/--help
- **错误处理**：完整的参数验证和友好错误提示
- **帮助系统**：详细的使用说明和示例
