#!/bin/bash
# Plugin: Telegram Bot — sing-box status notifications
#   sbx plugin telegram setup     configure bot
#   sbx plugin telegram test      send test message
#   sbx plugin telegram health    send health report
#   sbx plugin telegram on|off    enable/disable notifications

PLUGIN_TELEGRAM_VER="1.0.0"
PLUGIN_TELEGRAM_CONF="/etc/sbx/plugins/telegram.conf"

plugin_info() {
    echo "telegram|${PLUGIN_TELEGRAM_VER}|Telegram Bot — instant notifications & health reports"
}

plugin_init() {
    # Hook into service lifecycle — wrap manage() to send notifications
    if [[ -f "$PLUGIN_TELEGRAM_CONF" ]]; then
        . "$PLUGIN_TELEGRAM_CONF"
        [[ "$TG_ENABLED" == "1" ]] && _telegram_hook_install
    fi
}

# ── Configuration ─────────────────────────────────────────────
_telegram_setup() {
    echo
    _bright "  ▐▌ Telegram Bot Setup"
    _dim   "  ▐▌ configure your bot token and chat ID"
    echo
    echo -e "  ${c_dim}1. Create a bot with @BotFather on Telegram${c_none}"
    echo -e "  ${c_dim}2. Get your chat ID from @userinfobot${c_none}"
    echo

    echo -ne "  ${c_dim}Bot Token:${c_none} "
    read -r TG_TOKEN
    [[ ! $TG_TOKEN ]] && { warn "token required"; return; }

    echo -ne "  ${c_dim}Chat ID:${c_none} "
    read -r TG_CHAT_ID
    [[ ! $TG_CHAT_ID ]] && { warn "chat ID required"; return; }

    mkdir -p "$(dirname "$PLUGIN_TELEGRAM_CONF")"

    cat > "$PLUGIN_TELEGRAM_CONF" <<EOF
# Telegram Bot configuration
TG_TOKEN="$TG_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
TG_ENABLED="1"
TG_NOTIFY_START="1"
TG_NOTIFY_STOP="1"
TG_NOTIFY_CRASH="1"
TG_DAILY_HEALTH="1"
EOF
    # 安全：配置含 bot token，收緊權限（防止本機其他用戶讀取/注入）
    chmod 600 "$PLUGIN_TELEGRAM_CONF"

    _bright ">> Telegram configured"
    echo -e "  ${c_dim}test with:${c_none} sbx plugin telegram test"
}

# ── Send Message ───────────────────────────────────────────────
_telegram_send() {
    local text="$1"
    [[ ! -f "$PLUGIN_TELEGRAM_CONF" ]] && return 1
    . "$PLUGIN_TELEGRAM_CONF"
    [[ "$TG_ENABLED" != "1" || ! "$TG_TOKEN" || ! "$TG_CHAT_ID" ]] && return 1

    # Escape markdown special chars
    local escaped=$(echo -n "$text" | sed 's/[_*[\]()~`>#+-=|{}.!]/\\&/g')

    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        -d "text=${escaped}" \
        -d "parse_mode=MarkdownV2" \
        -d "disable_web_page_preview=true" \
        --connect-timeout 5 --max-time 10 \
        >/dev/null 2>&1

    return $?
}

# ── Test Connection ────────────────────────────────────────────
_telegram_test() {
    [[ ! -f "$PLUGIN_TELEGRAM_CONF" ]] && {
        warn "not configured. Run: sbx plugin telegram setup"
        return
    }
    . "$PLUGIN_TELEGRAM_CONF"

    echo
    _dim ">> testing Telegram connection..."

    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local ip=$(_wget -4 -qO- https://one.one.one.one/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p')

    local msg
    msg="✅ *sbx Telegram Bot*

━━━━━━━━━━━━━━━━
🖥 *Server:* \`${hostname}\`
📍 *IP:* \`${ip}\`
📦 *Version:* sbx ${is_sh_ver}
🕐 *Time:* $(date '+%Y-%m-%d %H:%M:%S')
━━━━━━━━━━━━━━━━
🟢 Connection successful\\!"

    if _telegram_send "$msg"; then
        _bright ">> test message sent — check your Telegram!"
    else
        warn "failed to send message — check your token and network"
    fi
}

# ── Health Report ──────────────────────────────────────────────
_telegram_health() {
    [[ ! -f "$PLUGIN_TELEGRAM_CONF" ]] && {
        warn "not configured. Run: sbx plugin telegram setup"
        return
    }

    echo
    _dim ">> sending health report..."

    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local core_running="🔴 stopped"
    pgrep -f "$is_core_bin" &>/dev/null && core_running="🟢 running"

    local config_count=$(ls "$is_conf_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local conns=$(ss -tnp 2>/dev/null | grep -c "$is_core_bin" || echo 0)
    local mem=$(free -m 2>/dev/null | awk '/Mem/{printf "%.0fMB", $3}')
    local disk=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
    local uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')

    # Quick health score
    local score=0
    pgrep -f "$is_core_bin" &>/dev/null && score=$((score + 25))
    [[ -f "$is_tls_cer" ]] && score=$((score + 25))
    ss -tlnp 2>/dev/null | grep -q "$is_core_bin" && score=$((score + 25))
    host -W2 google.com &>/dev/null && score=$((score + 25))

    local stars=""
    for ((i=0; i<5; i++)); do
        [[ $i -lt $((score / 20)) ]] && stars+="★" || stars+="☆"
    done

    local msg
    msg="📊 *Health Report*

━━━━━━━━━━━━━━━━
🖥 *Server:* \`${hostname}\`
⏱ *Uptime:* ${uptime_str}
━━━━━━━━━━━━━━━━
📡 *sing\\-box:* ${core_running}
📦 *Configs:* ${config_count}
🔗 *Connections:* ${conns}
━━━━━━━━━━━━━━━━
💯 *Health:* ${score}/100 ${stars}
💾 *Memory:* ${mem}
💿 *Disk:* ${disk} free
━━━━━━━━━━━━━━━━
🕐 *$(date '+%Y-%m-%d %H:%M')*"

    if _telegram_send "$msg"; then
        _bright ">> health report sent!"
    else
        warn "failed to send"
    fi
}

# ── Lifecycle Hooks ────────────────────────────────────────────
_telegram_hook_install() {
    # Called by plugin_init() — hooks into service events
    # Posts notification when sing-box is manually started/stopped/restarted

    # Store original manage function if not already wrapped
    if ! declare -f _manage_original &>/dev/null; then
        eval "_manage_original$(declare -f manage | tail -n +2)"
    fi

    manage() {
        local action="$1"
        local target="${2:-sing-box}"

        _manage_original "$@"

        # Notify on start/stop/restart
        if [[ "$target" == "sing-box" || -z "$2" ]]; then
            local hostname=$(hostname 2>/dev/null || echo "unknown")
            case "$action" in
                start|1)
                    sleep 3
                    if pgrep -f "$is_core_bin" &>/dev/null; then
                        _telegram_send "🟢 *sing\\-box started*

━━━━━━━━━━━━━━━━
🖥 \`${hostname}\`
🕐 $(date '+%H:%M:%S')"
                    else
                        _telegram_send "🔴 *sing\\-box FAILED to start*

━━━━━━━━━━━━━━━━
🖥 \`${hostname}\`
🕐 $(date '+%H:%M:%S')"
                    fi
                    ;;
                stop|2)
                    _telegram_send "⚫ *sing\\-box stopped*

━━━━━━━━━━━━━━━━
🖥 \`${hostname}\`
🕐 $(date '+%H:%M:%S')"
                    ;;
                restart|3|r)
                    sleep 3
                    if pgrep -f "$is_core_bin" &>/dev/null; then
                        _telegram_send "🔄 *sing\\-box restarted*

━━━━━━━━━━━━━━━━
🖥 \`${hostname}\`
🕐 $(date '+%H:%M:%S')"
                    else
                        _telegram_send "🔴 *sing\\-box FAILED to restart*

━━━━━━━━━━━━━━━━
🖥 \`${hostname}\`
🕐 $(date '+%H:%M:%S')"
                    fi
                    ;;
            esac
        fi
    }
}

# ── Toggle Notifications ───────────────────────────────────────
_telegram_toggle() {
    [[ ! -f "$PLUGIN_TELEGRAM_CONF" ]] && {
        warn "not configured. Run: sbx plugin telegram setup"
        return
    }
    . "$PLUGIN_TELEGRAM_CONF"

    case "$1" in
        on|enable|1)
            _sed "s/^TG_ENABLED=.*/TG_ENABLED=\"1\"/" "$PLUGIN_TELEGRAM_CONF"
            _telegram_hook_install
            _bright ">> Telegram notifications: ON"
            ;;
        off|disable|0)
            _sed "s/^TG_ENABLED=.*/TG_ENABLED=\"0\"/" "$PLUGIN_TELEGRAM_CONF"
            _bright ">> Telegram notifications: OFF"
            ;;
        *)
            echo -e "  ${c_dim}usage:${c_none} sbx plugin telegram on|off"
            [[ "$TG_ENABLED" == "1" ]] && echo -e "  ${c_dim}status:${c_none}  ${c_bright}ON${c_none}" || echo -e "  ${c_dim}status:${c_none}  ${c_dim}OFF${c_none}"
            ;;
    esac
}

# ── Plugin Entry ───────────────────────────────────────────────
telegram_main() {
    case "${1,,}" in
        setup|config|configure) _telegram_setup ;;
        test|ping)              _telegram_test ;;
        health|report|status)   _telegram_health ;;
        on|enable)             _telegram_toggle on ;;
        off|disable)           _telegram_toggle off ;;
        *)
            plugin_menu "Telegram Bot v${PLUGIN_TELEGRAM_VER}" \
                "instant notifications & health reports" \
                "setup" "setup — configure bot token and chat ID" \
                "test" "test — send test message" \
                "health" "health — send health report" \
                "on" "on — enable notifications" \
                "off" "off — disable notifications"
            [[ $REPLY ]] && telegram_main "$REPLY"
            echo
            if [[ -f "$PLUGIN_TELEGRAM_CONF" ]]; then
                . "$PLUGIN_TELEGRAM_CONF"
                [[ "$TG_ENABLED" == "1" ]] && echo -e "  ${c_bright}status: ON ✓${c_none}" || echo -e "  ${c_dim}status: OFF${c_none}"
            else
                echo -e "  ${c_dim}not configured${c_none}"
            fi
            echo
            ;;
    esac
}
