# dashboard.sh — sbx interactive dashboard
# Shows health score, navigation menu, and handles sub-menus

is_sbx_splash=0

# ── Dashboard header ──────────────────────────────────────────
dashboard_header() {
    local core_icon=">>"
    [[ $is_core_status =~ "running" ]] && core_icon="${c_bright}>>${c_none}" || core_icon="${c_dim}>>${c_none}"

    if [[ $is_sbx_splash -eq 0 ]]; then
        sleep 0.08
        echo -e " ${c_border}┌─────────────────────────────────────────────┐${c_none}"
        sleep 0.08
        echo -e " ${c_border}│${c_none} ${c_bright}▐▌ ▀█▀ █▀▄ ▀ ▀${c_none}  ${c_bright}sbx ${is_sh_ver}${c_none}  $core_icon   ${c_border}│${c_none}"
        sleep 0.08
        echo -e " ${c_border}│${c_none} ${c_dim}▐▌  █  █▀  ▀█▀${c_none}  ${c_dim}modern sing-box manager${c_none}  ${c_border}│${c_none}"
        sleep 0.08
        echo -e " ${c_border}└─────────────────────────────────────────────┘${c_none}"
        sleep 0.08
        is_sbx_splash=1
    else
        echo -e " ${c_border}┌─────────────────────────────────────────────┐${c_none}"
        echo -e " ${c_border}│${c_none} ${c_bright}▐▌ ▀█▀ █▀▄ ▀ ▀${c_none}  ${c_bright}sbx ${is_sh_ver}${c_none}  $core_icon   ${c_border}│${c_none}"
        echo -e " ${c_border}│${c_none} ${c_dim}▐▌  █  █▀  ▀█▀${c_none}  ${c_dim}modern sing-box manager${c_none}  ${c_border}│${c_none}"
        echo -e " ${c_border}└─────────────────────────────────────────────┘${c_none}"
    fi
}

# ── Quick health bar ─────────────────────────────────────────
dashboard_health() {
    # Quick health: core running + any port listening
    local h=0
    pgrep -f "$is_core_bin" &>/dev/null && h=$((h+1))
    [[ $is_core_stop ]] || h=$((h+1))
    # Count configs
    local config_count=$(ls "$is_conf_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
    port_count=$(ss -tlnp 2>/dev/null | grep -c "$is_core_bin" || echo 0)

    local stars=""
    for ((i=0; i<5; i++)); do
        [[ $i -lt $h || $h -ge 3 ]] && stars+="${c_bright}★${c_none}" || stars+="${c_dim}☆${c_none}"
    done

    echo -e "  Health: ${c_bright}$(( h * 25 + 25 ))/100${c_none} $stars  ${c_dim}${config_count} configs${c_none}"
    echo
}

# ── Navigation grid ──────────────────────────────────────────
dashboard_nav() {
    local zh=0
    [[ -f "$is_core_dir/lang" ]] && grep -q 'zh-TW' "$is_core_dir/lang" && zh=1

    if [[ $zh == 1 ]]; then
        echo -e "  ${c_dim}[1]${c_none} 建立配置     ${c_dim}[2]${c_none} 管理配置"
        echo -e "  ${c_dim}[3]${c_none} DNS          ${c_dim}[4]${c_none} 工具"
        echo -e "  ${c_dim}[5]${c_none} 配置檔       ${c_dim}[6]${c_none} 系統"
        echo -e "  ${c_dim}[7]${c_none} 主題         ${c_dim}[8]${c_none} 插件"
        echo -e "  ${c_dim}[9]${c_none} 幫助         ${c_dim}[0]${c_none} 離開"
    else
        echo -e "  ${c_dim}[1]${c_none} Create       ${c_dim}[2]${c_none} Manage"
        echo -e "  ${c_dim}[3]${c_none} DNS          ${c_dim}[4]${c_none} Tools"
        echo -e "  ${c_dim}[5]${c_none} Profiles     ${c_dim}[6]${c_none} System"
        echo -e "  ${c_dim}[7]${c_none} Themes       ${c_dim}[8]${c_none} Plugins"
        echo -e "  ${c_dim}[9]${c_none} Help         ${c_dim}[0]${c_none} Exit"
    fi
    echo
    echo -e "  ${c_dim}[m]${c_none} Matrix"
}

# ── Sub menu helper ──────────────────────────────────────────
dashboard_sub() {
    local title=$1
    shift
    echo
    echo -e " ${c_bright}▐▌ ${c_dim}${title}${c_none}"
    echo -e " ${c_dim}----------------${c_none}"
    local i=1
    for item in "$@"; do
        echo -e "  ${c_dim}[$i]${c_none} $item"
        ((i++))
    done
    echo -ne " ${c_bright}>${c_none} "
    read -r REPLY
}

# ── Main dashboard entry ─────────────────────────────────────
dashboard_main() {
    clear 2>/dev/null
    dashboard_header
    dashboard_health
    dashboard_nav
    echo -ne " ${c_bright}>>${c_none} "
    read -r REPLY

    [[ ! $REPLY ]] && return

    local zh=0
    [[ -f "$is_core_dir/lang" ]] && grep -q 'zh-TW' "$is_core_dir/lang" && zh=1

    is_main_start=1

    case $REPLY in
    1)  # Create config — interactive protocol selection
        add
        ;;
    2)  # Manage configs
        if [[ $zh == 1 ]]; then
            dashboard_sub "manage" "查看配置" "更改配置" "刪除配置" "分享連結" "QR碼"
        else
            dashboard_sub "manage" "view" "change" "delete" "url" "qr"
        fi
        case $REPLY in
            1) info ;;
            2) change ;;
            3) del ;;
            4) url_qr url ;;
            5) url_qr qr ;;
        esac
        ;;
    3)  # DNS
        if [[ $zh == 1 ]]; then
            dashboard_sub "dns" "NextDNS" "Cloudflare" "Google" "1.1.1.1" "8.8.8.8" "Family" "自訂" "清除"
        else
            dashboard_sub "dns" "NextDNS" "Cloudflare" "Google" "1.1.1.1" "8.8.8.8" "Family" "Custom" "Clear"
        fi
        load dns.sh
        case $REPLY in
            1) dns_set_nextdns ;;
            2) dns_set cf ;;
            3) dns_set gg ;;
            4) dns_set 11 ;;
            5) dns_set 88 ;;
            6) dns_set family ;;
            7) dns_set set ;;
            8) dns_set none ;;
        esac
        ;;
    4)  # Tools
        if [[ $zh == 1 ]]; then
            dashboard_sub "tools" "測速" "健康檢查" "系統診斷" "協議基準測試" "備份" "流量統計" "日誌"
        else
            dashboard_sub "tools" "speed" "health" "doctor" "bench" "backup" "traffic" "log"
        fi
        case $REPLY in
            1) load speed.sh; speed_set ;;
            2) load check.sh; check_set ;;
            3) load doctor.sh; doctor_run ;;
            4) load bench.sh; bench_run ;;
            5) load backup.sh; backup_set ;;
            6) load traffic.sh; traffic_set ;;
            7) load log.sh; log_set ;;
        esac
        ;;
    5)  # Profiles
        load profile.sh
        if [[ $zh == 1 ]]; then
            dashboard_sub "profiles" "列表" "儲存" "切換" "刪除"
        else
            dashboard_sub "profiles" "list" "save" "switch" "delete"
        fi
        case $REPLY in
            1) profile_main list ;;
            2) profile_main save ;;
            3) profile_main switch ;;
            4) profile_main delete ;;
        esac
        ;;
    6)  # System
        if [[ $zh == 1 ]]; then
            dashboard_sub "system" "運行管理" "BBR" "日誌" "更新" "重裝" "卸載"
        else
            dashboard_sub "system" "service" "BBR" "log" "update" "reinstall" "uninstall"
        fi
        case $REPLY in
            1)
                if [[ $zh == 1 ]]; then
                    dashboard_sub "service" "啟動" "停止" "重啟" "狀態"
                else
                    dashboard_sub "service" "start" "stop" "restart" "status"
                fi
                manage $REPLY &
                ;;
            2) load bbr.sh; _try_enable_bbr ;;
            3) load log.sh; log_set ;;
            4)
                if [[ $zh == 1 ]]; then
                    dashboard_sub "update" "核心" "腳本"
                else
                    dashboard_sub "update" "core" "script"
                fi
                case $REPLY in
                    1) update core ;;
                    2) update sh ;;
                esac
                ;;
            5) get reinstall ;;
            6) uninstall ;;
        esac
        ;;
    7)  # Themes
        load theme.sh
        echo
        theme_list
        echo -ne " ${c_dim}theme name (Enter to keep):${c_none} "
        read -r theme_choice
        [[ $theme_choice ]] && theme_set "$theme_choice"
        ;;
    8)  # Plugins
        load plugin.sh
        plugin_list
        ;;
    9)  # Help
        load help.sh
        if [[ $zh == 1 ]]; then
            dashboard_sub "help" "幫助" "關於" "語言" "返回"
        else
            dashboard_sub "help" "help" "about" "language" "back"
        fi
        case $REPLY in
            1) show_help ;;
            2) about ;;
            3)
                echo -e "  ${c_dim}sbx lang zh-TW${c_none}"
                echo -e "  ${c_dim}sbx lang en${c_none}"
                ;;
        esac
        ;;
    0 | q | Q | exit)
        echo -e "  ${c_dim}bye!${c_none}"
        exit 0
        ;;
    m | M)
        load matrix.sh
        matrix_set
        is_sbx_splash=0
        ;;
    esac
}
