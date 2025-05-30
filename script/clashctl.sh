# shellcheck disable=SC2148
# shellcheck disable=SC2155

function clashon() {
    _get_proxy_port
    sudo systemctl start "$BIN_KERNEL_NAME" && _okcat '已开启代理环境' ||
        _failcat '启动失败: 执行 "clashstatus" 查看日志' || return 1

    local auth=$(sudo "$BIN_YQ" '.authentication[0] // ""' "$CLASH_CONFIG_RUNTIME")
    [ -n "$auth" ] && auth=$auth@

    local http_proxy_addr="http://${auth}127.0.0.1:${MIXED_PORT}"
    local socks_proxy_addr="socks5h://${auth}127.0.0.1:${MIXED_PORT}"
    local no_proxy_addr="localhost,127.0.0.1,::1"

    export http_proxy=$http_proxy_addr
    export https_proxy=$http_proxy
    export HTTP_PROXY=$http_proxy
    export HTTPS_PROXY=$http_proxy

    export all_proxy=$socks_proxy_addr
    export ALL_PROXY=$all_proxy

    export no_proxy=$no_proxy_addr
    export NO_PROXY=$no_proxy
}

watch_proxy() {
    systemctl is-active "$BIN_KERNEL_NAME" >&/dev/null && [ -z "$http_proxy" ] && {
        if _is_root; then
            clashon
        else
            _failcat '未检测到代理变量，可执行 clashon 开启代理环境'
        fi
    }
}

function clashoff() {
    sudo systemctl stop "$BIN_KERNEL_NAME" && _okcat '已关闭代理环境' ||
        _failcat '关闭失败: 执行 "clashstatus" 查看日志' || return 1

    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY
    unset no_proxy
    unset NO_PROXY
}

clashrestart() {
    { clashoff && clashon; } >&/dev/null
}

function clashstatus() {
    sudo systemctl status "$BIN_KERNEL_NAME" "$@"
}

function clashui() {
    # 防止tun模式强制走代理获取不到真实公网ip
    clashoff >&/dev/null
    _get_ui_port
    # 公网ip
    # ifconfig.me
    local query_url='api64.ipify.org'
    local public_ip=$(curl -s --noproxy "*" --connect-timeout 2 $query_url)
    local public_address="http://${public_ip:-公网}:${UI_PORT}/ui"
    # 内网ip
    # ip route get 1.1.1.1 | grep -oP 'src \K\S+'
    local local_ip=$(hostname -I | awk '{print $1}')
    local local_address="http://${local_ip}:${UI_PORT}/ui"
    printf "\n"
    printf "╔═══════════════════════════════════════════════╗\n"
    printf "║                %s                  ║\n" "$(_okcat 'Web 控制台')"
    printf "║═══════════════════════════════════════════════║\n"
    printf "║                                               ║\n"
    printf "║     🔓 注意放行端口：%-5s                    ║\n" "$UI_PORT"
    printf "║     🏠 内网：%-31s  ║\n" "$local_address"
    printf "║     🌏 公网：%-31s  ║\n" "$public_address"
    printf "║     ☁️  公共：%-31s  ║\n" "$URL_CLASH_UI"
    printf "║                                               ║\n"
    printf "╚═══════════════════════════════════════════════╝\n"
    printf "\n"
    clashon >&/dev/null
}

_merge_config_restart() {
    local backup="/tmp/rt.backup"
    sudo cat "$CLASH_CONFIG_RUNTIME" 2>/dev/null | sudo tee $backup >&/dev/null
    sudo "$BIN_YQ" eval-all '. as $item ireduce ({}; . *+ $item)' "$CLASH_CONFIG_RAW" "$CLASH_CONFIG_MIXIN" | sudo tee "$CLASH_CONFIG_RUNTIME" >&/dev/null
    _valid_config "$CLASH_CONFIG_RUNTIME" || {
        sudo cat $backup | sudo tee "$CLASH_CONFIG_RUNTIME" >&/dev/null
        _error_quit "验证失败：请检查 Mixin 配置"
    }
    clashrestart
}

function clashsecret() {
    case "$#" in
    0)
        _okcat "当前密钥：$(sudo "$BIN_YQ" '.secret // ""' "$CLASH_CONFIG_RUNTIME")"
        ;;
    1)
        sudo "$BIN_YQ" -i ".secret = \"$1\"" "$CLASH_CONFIG_MIXIN" || {
            _failcat "密钥更新失败，请重新输入"
            return 1
        }
        _merge_config_restart
        _okcat "密钥更新成功，已重启生效"
        ;;
    *)
        _failcat "密钥不要包含空格或使用引号包围"
        ;;
    esac
}

_tunstatus() {
    local tun_status=$(sudo "$BIN_YQ" '.tun.enable' "${CLASH_CONFIG_RUNTIME}")
    # shellcheck disable=SC2015
    [ "$tun_status" = 'true' ] && _okcat 'Tun 状态：启用' || _failcat 'Tun 状态：关闭'
}

_tunoff() {
    _tunstatus >/dev/null || return 0
    sudo "$BIN_YQ" -i '.tun.enable = false' "$CLASH_CONFIG_MIXIN"
    _merge_config_restart && _okcat "Tun 模式已关闭"
}

_tunon() {
    _tunstatus 2>/dev/null && return 0
    sudo "$BIN_YQ" -i '.tun.enable = true' "$CLASH_CONFIG_MIXIN"
    _merge_config_restart
    sleep 0.5s
    sudo journalctl -u "$BIN_KERNEL_NAME" --since "1 min ago" | grep -E -m1 'unsupported kernel version|Start TUN listening error' && {
        _tunoff >&/dev/null
        _error_quit '不支持的内核版本'
    }
    _okcat "Tun 模式已开启"
}

function clashtun() {
    case "$1" in
    on)
        _tunon
        ;;
    off)
        _tunoff
        ;;
    *)
        _tunstatus
        ;;
    esac
}

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
                cat <<EOF

Usage: clash log [OPTIONS]

查看 mihomo/clash 服务日志

Options:
    -f, --follow         实时跟踪日志输出
    -n, --lines NUMBER   显示最后 N 行日志 (默认: 50)
    -h, --help          显示此帮助信息

Examples:
    clash log                    # 显示最后50行日志
    clash log -n 100            # 显示最后100行日志
    clash log -f                # 实时跟踪日志
    clash log -f -n 20          # 显示最后20行并实时跟踪

EOF
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

    # 构建 journalctl 命令
    local cmd="sudo journalctl -u ${BIN_KERNEL_NAME}"

    if [[ "$follow" == "true" ]]; then
        cmd="$cmd -f"
        _okcat "🔍" "实时跟踪 ${BIN_KERNEL_NAME} 日志 (按 Ctrl+C 退出)..."
    else
        _okcat "📋" "显示 ${BIN_KERNEL_NAME} 最后 ${lines} 行日志..."
    fi

    cmd="$cmd -n ${lines} --no-pager"

    # 执行命令
    eval "$cmd"
}

function clashreload() {
    local config_file="${CLASH_CONFIG_RUNTIME}"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<EOF

Usage: clash reload [OPTIONS]

重新加载 mihomo/clash 配置文件

Options:
    -h, --help       显示此帮助信息

说明:
    重新加载 mihomo 配置文件，通过重启服务来应用新配置。
    配置文件路径: ${config_file}

Examples:
    clash reload                 # 重载配置文件

EOF
                return 0
                ;;
            *)
                _failcat "未知参数: $1"
                _failcat "使用 'clash reload --help' 查看帮助"
                return 1
                ;;
        esac
    done

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        _failcat "错误: 配置文件不存在: $config_file"
        return 1
    fi

    # 验证配置文件
    _okcat "🔍" "验证配置文件..."
    if ! _valid_config "$config_file"; then
        _failcat "❌" "配置文件验证失败，请检查配置文件语法"
        return 1
    fi

    # 重启服务以应用新配置
    _okcat "🔄" "重启服务以应用新配置..."
    clashrestart
    _okcat "✅" "配置重载完成"
    return 0
}

function clashupdate() {
    local url=$(cat "$CLASH_CONFIG_URL")
    local is_auto

    case "$1" in
    auto)
        is_auto=true
        [ -n "$2" ] && url=$2
        ;;
    log)
        sudo tail "${CLASH_UPDATE_LOG}" 2>/dev/null || _failcat "暂无更新日志"
        return 0
        ;;
    *)
        [ -n "$1" ] && url=$1
        ;;
    esac

    # 如果没有提供有效的订阅链接（url为空或者不是http开头），则使用默认配置文件
    [ "${url:0:4}" != "http" ] && {
        _failcat "没有提供有效的订阅链接：使用 ${CLASH_CONFIG_RAW} 进行更新..."
        url="file://$CLASH_CONFIG_RAW"
    }

    # 如果是自动更新模式，则设置定时任务
    [ "$is_auto" = true ] && {
        sudo grep -qs 'clashupdate' "$CLASH_CRON_TAB" || echo "0 0 */2 * * $_SHELL -i -c '. $SHELL_RC;clashupdate $url'" | sudo tee -a "$CLASH_CRON_TAB" >&/dev/null
        _okcat "已设置定时更新订阅" && return 0
    }

    _okcat '👌' "正在下载：原配置已备份..."
    sudo cat "$CLASH_CONFIG_RAW" | sudo tee "$CLASH_CONFIG_RAW_BAK" >&/dev/null

    _rollback() {
        _failcat '🍂' "$1"
        sudo cat "$CLASH_CONFIG_RAW_BAK" | sudo tee "$CLASH_CONFIG_RAW" >&/dev/null
        _failcat '❌' "[$(date +"%Y-%m-%d %H:%M:%S")] 订阅更新失败：$url" 2>&1 | sudo tee -a "${CLASH_UPDATE_LOG}" >&/dev/null
        _error_quit
    }

    _download_config "$CLASH_CONFIG_RAW" "$url" || _rollback "下载失败：已回滚配置"
    _valid_config "$CLASH_CONFIG_RAW" || _rollback "转换失败：已回滚配置，转换日志：$BIN_SUBCONVERTER_LOG"

    _merge_config_restart && _okcat '🍃' '订阅更新成功'
    echo "$url" | sudo tee "$CLASH_CONFIG_URL" >&/dev/null
    _okcat '✅' "[$(date +"%Y-%m-%d %H:%M:%S")] 订阅更新成功：$url" | sudo tee -a "${CLASH_UPDATE_LOG}" >&/dev/null
}

function clashmixin() {
    case "$1" in
    -e)
        sudo vim "$CLASH_CONFIG_MIXIN" && {
            _merge_config_restart && _okcat "配置更新成功，已重启生效"
        }
        ;;
    -r)
        less -f "$CLASH_CONFIG_RUNTIME"
        ;;
    *)
        less -f "$CLASH_CONFIG_MIXIN"
        ;;
    esac
}

function clashctl() {
    case "$1" in
    on)
        clashon
        ;;
    off)
        clashoff
        ;;
    ui)
        clashui
        ;;
    status)
        shift
        clashstatus "$@"
        ;;

    tun)
        shift
        clashtun "$@"
        ;;
    mixin)
        shift
        clashmixin "$@"
        ;;
    secret)
        shift
        clashsecret "$@"
        ;;
    update)
        shift
        clashupdate "$@"
        ;;
    log)
        shift
        clashlog "$@"
        ;;
    reload)
        shift
        clashreload "$@"
        ;;
    restart)
        clashrestart
        ;;
    *)
        cat <<EOF

Usage:
    clash      COMMAND  [OPTION]
    mihomo     COMMAND  [OPTION]
    clashctl   COMMAND  [OPTION]
    mihomoctl  COMMAND  [OPTION】

Commands:
    on                   开启代理
    off                  关闭代理
    ui                   面板地址
    status               内核状况
    log      [-f] [-n N] 查看日志
    reload               重载配置
    restart              重启服务
    tun      [on|off]    Tun 模式
    mixin    [-e|-r]     Mixin 配置
    secret   [SECRET]    Web 密钥
    update   [auto|log]  更新订阅

EOF
        ;;
    esac
}

function mihomoctl() {
    clashctl "$@"
}

function clash() {
    clashctl "$@"
}

function mihomo() {
    clashctl "$@"
}
