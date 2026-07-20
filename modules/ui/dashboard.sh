# dashboard.sh — sbx interactive dashboard
# Shows health score, navigation menu, and handles sub-menus

is_sbx_splash=0

# ── Pause helper ───────────────────────────────────────────────
_pause() {
    echo
    echo -ne " ${c_dim}Press Enter to continue...${c_none}"
    read -r
}

# ── Dashboard header ──────────────────────────────────────────
dashboard_header() {
    local core_icon=">>"
    [[ $is_core_status =~ "running" ]] && core_icon="${c_bright}>>${c_none}" || core_icon="${c_dim}>>${c_none}"

    echo
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
    local h=0
    pgrep -f "$is_core_bin" &>/dev/null && h=$((h+1))
    [[ $is_core_stop ]] || h=$((h+1))
    local config_count=$(ls "$is_conf_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')

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

# ── Helper: pick a config file ────────────────────────────────
_pick_config() {
    local files=($(ls "$is_conf_dir"/*.json 2>/dev/null))
    if [[ ${#files[@]} -eq 0 ]]; then
        warn "no config files found"
        return 1
    elif [[ ${#files[@]} -eq 1 ]]; then
        is_picked_config=$(basename "${files[0]}" .json)
        _dim ">> auto-selected: $is_picked_config"
    else
        echo
        local i=1
        for f in "${files[@]}"; do
            local name=$(basename "$f" .json)
            local proto=$(jq -r '.inbounds[0].type // "?"' "$f" 2>/dev/null)
            local port=$(jq -r '.inbounds[0].listen_port // "?"' "$f" 2>/dev/null)
            echo -e "  ${c_dim}[$i]${c_none} ${c_bright}${name}${c_none}  ${c_dim}${proto} :${port}${c_none}"
            ((i++))
        done
        echo -ne " ${c_bright}>${c_none} "
        read -r pick
        [[ $pick =~ ^[0-9]+$ && $pick -ge 1 && $pick -le ${#files[@]} ]] || {
            _dim ">> cancelled"
            return 1
        }
        is_picked_config=$(basename "${files[$((pick-1))]}" .json)
    fi
    return 0
}

# ── Main dashboard entry ─────────────────────────────────────
dashboard_main() {
    # Don't clear screen — let previous output be visible above the menu
    dashboard_header
    dashboard_health
    dashboard_nav
    echo -ne " ${c_bright}>>${c_none} "
    read -r REPLY

    [[ ! $REPLY ]] && return

    local zh=0
    [[ -f "$is_core_dir/lang" ]] && grep -q 'zh-TW' "$is_core_dir/lang" && zh=1

    is_main_start=1
    # Prevent err() from killing the dashboard session
    is_dont_auto_exit=1

    case $REPLY in
    # ── [1] Create ──────────────────────────────────────────
    1)
        add
        _pause
        ;;

    # ── [2] Manage ──────────────────────────────────────────
    2)
        if [[ $zh == 1 ]]; then
            dashboard_sub "manage" "查看配置" "更改配置" "刪除配置" "分享連結" "QR碼" "返回"
        else
            dashboard_sub "manage" "view" "change" "delete" "url" "qr" "back"
        fi
        case $REPLY in
            1)
                _pick_config || { _pause; return; }
                info "$is_picked_config"
                _pause
                ;;
            2)
                _pick_config || { _pause; return; }
                change "$is_picked_config"
                _pause
                ;;
            3)
                _pick_config || { _pause; return; }
                is_no_del_msg=1
                del "$is_picked_config"
                _pause
                ;;
            4)
                _pick_config || { _pause; return; }
                url_qr url "$is_picked_config"
                _pause
                ;;
            5)
                _pick_config || { _pause; return; }
                url_qr qr "$is_picked_config"
                _pause
                ;;
            *) return ;;
        esac
        ;;

    # ── [3] DNS ─────────────────────────────────────────────
    3)
        if [[ $zh == 1 ]]; then
            dashboard_sub "dns" "NextDNS" "Cloudflare" "Google" "1.1.1.1" "8.8.8.8" "Family" "自訂" "清除" "返回"
        else
            dashboard_sub "dns" "NextDNS" "Cloudflare" "Google" "1.1.1.1" "8.8.8.8" "Family" "Custom" "Clear" "Back"
        fi
        load dns.sh
        case $REPLY in
            1) dns_set_nextdns ; _pause ;;
            2) dns_set cf ; _pause ;;
            3) dns_set gg ; _pause ;;
            4) dns_set 11 ; _pause ;;
            5) dns_set 88 ; _pause ;;
            6) dns_set family ; _pause ;;
            7) dns_set set ; _pause ;;
            8) dns_set none ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [4] Tools ───────────────────────────────────────────
    4)
        if [[ $zh == 1 ]]; then
            dashboard_sub "tools" "測速" "健康檢查" "系統診斷" "協議基準測試" "備份" "流量統計" "日誌" "返回"
        else
            dashboard_sub "tools" "speed" "health" "doctor" "bench" "backup" "traffic" "log" "back"
        fi
        case $REPLY in
            1) load speed.sh; speed_set ; _pause ;;
            2) load check.sh; check_set ; _pause ;;
            3) load doctor.sh; doctor_run ; _pause ;;
            4) load bench.sh; bench_run ; _pause ;;
            5) load backup.sh; backup_set ; _pause ;;
            6) load traffic.sh; traffic_set ; _pause ;;
            7) load log.sh; log_set ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [5] Profiles ────────────────────────────────────────
    5)
        load profile.sh
        if [[ $zh == 1 ]]; then
            dashboard_sub "profiles" "列表" "儲存" "切換" "刪除" "返回"
        else
            dashboard_sub "profiles" "list" "save" "switch" "delete" "back"
        fi
        case $REPLY in
            1) profile_main list ; _pause ;;
            2) profile_main save ; _pause ;;
            3) profile_main switch ; _pause ;;
            4) profile_main delete ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [6] System ──────────────────────────────────────────
    6)
        if [[ $zh == 1 ]]; then
            dashboard_sub "system" "運行管理" "BBR" "日誌" "更新" "重裝" "卸載" "返回"
        else
            dashboard_sub "system" "service" "BBR" "log" "update" "reinstall" "uninstall" "back"
        fi
        case $REPLY in
            1)  # service submenu
                if [[ $zh == 1 ]]; then
                    dashboard_sub "service" "啟動" "停止" "重啟" "狀態" "返回"
                else
                    dashboard_sub "service" "start" "stop" "restart" "status" "back"
                fi
                case $REPLY in
                    1) manage start & _pause ;;
                    2) manage stop & _pause ;;
                    3) manage restart & _pause ;;
                    4) ;;  # status already shows
                    *) return ;;
                esac
                ;;
            2) load bbr.sh; _try_enable_bbr ; _pause ;;
            3) load log.sh; log_set ; _pause ;;
            4)  # update submenu
                if [[ $zh == 1 ]]; then
                    dashboard_sub "update" "核心" "腳本" "返回"
                else
                    dashboard_sub "update" "core" "script" "back"
                fi
                case $REPLY in
                    1) update core ; _pause ;;
                    2) update sh ; _pause ;;
                    *) return ;;
                esac
                ;;
            5) get reinstall ; _pause ;;
            6) uninstall ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [7] Themes ──────────────────────────────────────────
    7)
        load theme.sh
        echo
        theme_list
        echo
        echo -ne " ${c_dim}theme name (Enter to keep):${c_none} "
        read -r theme_choice
        [[ $theme_choice ]] && theme_set "$theme_choice"
        _pause
        ;;

    # ── [8] Plugins ─────────────────────────────────────────
    8)
        load plugin.sh
        plugin_list
        echo -ne " ${c_dim}plugin name for details (Enter to skip):${c_none} "
        read -r plugin_choice
        if [[ $plugin_choice ]]; then
            plugin_dispatch "$plugin_choice"
        fi
        _pause
        ;;

    # ── [9] Help ────────────────────────────────────────────
    9)
        load help.sh
        if [[ $zh == 1 ]]; then
            dashboard_sub "help" "幫助" "關於" "語言" "返回"
        else
            dashboard_sub "help" "help" "about" "language" "back"
        fi
        case $REPLY in
            1) show_help ; _pause ;;
            2) about ; _pause ;;
            3)
                echo -e "  ${c_dim}sbx lang zh-TW${c_none}"
                echo -e "  ${c_dim}sbx lang en${c_none}"
                _pause
                ;;
            *) return ;;
        esac
        ;;

    # ── [0] Exit ────────────────────────────────────────────
    0 | q | Q | exit)
        echo -e "  ${c_dim}bye!${c_none}"
        exit 0
        ;;

    # ── [m] Matrix ──────────────────────────────────────────
    m | M)
        load matrix.sh
        matrix_set
        is_sbx_splash=0
        ;;

    # ── silent refresh (empty Enter) ────────────────────────
    "")
        ;;
    esac

    # Reset for next loop iteration
    is_dont_auto_exit=
}
