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
    [[ $is_core_status =~ "running" ]] && core_icon="${c_bright}▶${c_none}" || core_icon="${c_dim}■${c_none}"

    echo
    if [[ $is_sbx_splash -eq 0 ]]; then
        sleep 0.04
        echo -e "  ${c_bright}sbx ${is_sh_ver}${c_none}  ${core_icon}  ${c_dim}running${c_none}"
        sleep 0.06
        echo -e "  ${c_dim}Next Generation sing-box Manager${c_none}"
        sleep 0.04
        echo -e "  ${c_dim}─────────────────────────────────${c_none}"
        sleep 0.04
        echo -e "  ${c_accent}By: WAHSUN${c_none}"
        sleep 0.06
        is_sbx_splash=1
    else
        echo -e "  ${c_bright}sbx ${is_sh_ver}${c_none}  ${core_icon}  ${c_dim}running${c_none}"
        echo -e "  ${c_dim}Next Generation sing-box Manager${c_none}"
        echo -e "  ${c_dim}─────────────────────────────────${c_none}"
        echo -e "  ${c_accent}By: WAHSUN${c_none}"
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
        echo -e "  ${c_dim}[3]${c_none} 工具         ${c_dim}[4]${c_none} 系統"
        echo -e "  ${c_dim}[5]${c_none} 設定         ${c_dim}[0]${c_none} 離開"
    else
        echo -e "  ${c_dim}[1]${c_none} Create       ${c_dim}[2]${c_none} Manage"
        echo -e "  ${c_dim}[3]${c_none} Tools        ${c_dim}[4]${c_none} System"
        echo -e "  ${c_dim}[5]${c_none} Settings     ${c_dim}[0]${c_none} Exit"
    fi
    echo
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
    is_dashboard=1

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

    # ── [3] Tools ───────────────────────────────────────────
    3)
        if [[ $zh == 1 ]]; then
            dashboard_sub "tools" "測速" "健康檢查" "備份" "返回"
        else
            dashboard_sub "tools" "speed" "health" "backup" "back"
        fi
        case $REPLY in
            1) load speed.sh; speed_set ; _pause ;;
            2) load check.sh; check_set ; _pause ;;
            3) load backup.sh; backup_set ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [4] System ──────────────────────────────────────────
    4)
        if [[ $zh == 1 ]]; then
            dashboard_sub "system" "運行管理" "BBR" "日誌" "更新" "卸載" "返回"
        else
            dashboard_sub "system" "service" "BBR" "log" "update" "uninstall" "back"
        fi
        case $REPLY in
            1)  # service submenu
                if [[ $zh == 1 ]]; then
                    dashboard_sub "service" "啟動" "停止" "重啟" "返回"
                else
                    dashboard_sub "service" "start" "stop" "restart" "back"
                fi
                case $REPLY in
                    1) manage start & _pause ;;
                    2) manage stop & _pause ;;
                    3) manage restart & _pause ;;
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
            5) uninstall ; _pause ;;
            *) return ;;
        esac
        ;;

    # ── [5] Settings (themes / plugins / help) ──────────────
    5)
        if [[ $zh == 1 ]]; then
            dashboard_sub "settings" "主題" "插件" "幫助" "語言" "返回"
        else
            dashboard_sub "settings" "theme" "plugin" "help" "language" "back"
        fi
        case $REPLY in
            1)  # theme picker
                load theme.sh
                echo
                _dim "  >> available themes"
                echo
                local themes=()
                for f in "$THEME_DIR"/*.sh; do
                    [[ -f "$f" ]] || continue
                    themes+=("$(basename "$f" .sh)")
                done
                local i=1
                for t in "${themes[@]}"; do
                    local marker=" "
                    [[ "$t" == "$is_theme" ]] && marker="${c_bright}*${c_none}"
                    echo -e "  ${c_dim}[$i]${c_none} $marker ${c_bright}$t${c_none}"
                    ((i++))
                done
                echo
                echo -ne " ${c_dim}select theme [1-${#themes[@]} / Enter=keep]:${c_none} "
                read -r theme_pick
                if [[ $theme_pick =~ ^[0-9]+$ && $theme_pick -ge 1 && $theme_pick -le ${#themes[@]} ]]; then
                    theme_set "${themes[$((theme_pick-1))]}"
                fi
                _pause
                ;;
            2)  # plugin picker
                load plugin.sh
                echo
                _dim "  >> installed plugins"
                echo
                local plugins=()
                if [[ -d "$PLUGIN_DIR" ]]; then
                    for d in "$PLUGIN_DIR"/*/; do
                        [[ -f "$d/plugin.sh" ]] || continue
                        plugins+=("$(basename "$d")")
                    done
                fi
                if [[ ${#plugins[@]} -eq 0 ]]; then
                    _dim "  no plugins installed"
                else
                    local i=1
                    for p in "${plugins[@]}"; do
                        local info=$(. "$PLUGIN_DIR/$p/plugin.sh" && plugin_info)
                        local name=$(echo "$info" | cut -d'|' -f1)
                        local desc=$(echo "$info" | cut -d'|' -f3)
                        echo -e "  ${c_dim}[$i]${c_none} ${c_bright}$name${c_none}  ${c_dim}$desc${c_none}"
                        ((i++))
                    done
                    echo
                    echo -ne " ${c_dim}select plugin [1-${#plugins[@]} / Enter=back]:${c_none} "
                    read -r plugin_pick
                    if [[ $plugin_pick =~ ^[0-9]+$ && $plugin_pick -ge 1 && $plugin_pick -le ${#plugins[@]} ]]; then
                        echo
                        plugin_dispatch "${plugins[$((plugin_pick-1))]}"
                    fi
                fi
                _pause
                ;;
            3) load help.sh; show_help ; _pause ;;
            4)
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

    # ── silent refresh (empty Enter) ────────────────────────
    "")
        ;;
    esac

    # Reset for next loop iteration
    is_dashboard=
}
