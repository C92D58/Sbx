# profile.sh — configuration profiles
#   sbx profile              list profiles
#   sbx profile save <name>  save current config as profile
#   sbx profile switch <name> switch to profile
#   sbx profile delete <name> delete profile

profile_dir=/etc/sbx/profiles

profile_main() {
    case ${1,,} in
        save)   profile_save "$2" ;;
        switch)
            [[ $2 ]] && profile_switch "$2" || profile_list
            ;;
        delete|del|rm) profile_delete "$2" ;;
        list|ls|"") profile_list ;;
        *) err "usage: sbx profile [list|save|switch|delete] <name>" ;;
    esac
}

profile_list() {
    echo
    _bright "  ▐▌ profiles"
    _dim   "  ▐▌ configuration snapshots"
    echo

    local found=0
    if [[ -d "$profile_dir" ]]; then
        for d in "$profile_dir"/*/; do
            [[ -d "$d" ]] || continue
            found=1
            local name=$(basename "$d")
            local count=$(ls "$d/conf"/*.json 2>/dev/null | wc -l | tr -d ' ')
            local ts=""
            [[ -f "$d/.created" ]] && ts=$(cat "$d/.created")
            printf "  ${c_bright}%-16s${c_none} ${c_dim}%s configs${c_none}  ${c_dim}%s${c_none}\n" \
                "$name" "$count" "$ts"
        done
    fi
    [[ $found -eq 0 ]] && _dim "  no profiles yet — use: sbx profile save <name>"
    echo
}

profile_save() {
    local name=$1
    [[ ! $name ]] && {
        echo -ne " ${c_dim}profile name:${c_none} "
        read -r name
    }
    [[ ! $name ]] && err "profile name required"
    # 安全：拒絕路徑穿越（.. / 絕對路徑 / 分隔符）
    [[ ! $name =~ ^[a-zA-Z0-9_\-]+$ ]] && err "profile name 含不允許的字符（僅字母數字 _-）"

    mkdir -p "$profile_dir/$name/conf"

    # copy config
    cp -f "$is_config_json" "$profile_dir/$name/config.json" 2>/dev/null
    cp -rf "$is_conf_dir"/*.json "$profile_dir/$name/conf/" 2>/dev/null

    # copy caddy configs if present
    if [[ $is_caddy ]] && [[ -f "$is_caddyfile" ]]; then
        cp -f "$is_caddyfile" "$profile_dir/$name/Caddyfile" 2>/dev/null
        [[ -d "$is_caddy_conf" ]] && cp -rf "$is_caddy_conf" "$profile_dir/$name/caddy_conf/" 2>/dev/null
    fi

    # metadata
    date +"%Y-%m-%d %H:%M" > "$profile_dir/$name/.created"

    _bright ">> profile saved: $name"
    echo -e " ${c_dim}$profile_dir/$name/${c_none}"
}

profile_switch() {
    local name=$1
    [[ ! -d "$profile_dir/$name" ]] && err "profile '$name' not found"

    echo
    _dim ">> switching to profile: $name"

    # backup current first
    profile_save "_auto-backup-$(date +%Y%m%d-%H%M%S)"

    # stop services
    manage stop &>/dev/null
    [[ $is_caddy ]] && manage stop caddy &>/dev/null

    # restore profile configs
    [[ -f "$profile_dir/$name/config.json" ]] && cp -f "$profile_dir/$name/config.json" "$is_config_json"
    [[ -d "$profile_dir/$name/conf" ]] && {
        rm -f "$is_conf_dir"/*.json
        cp -f "$profile_dir/$name/conf"/*.json "$is_conf_dir/" 2>/dev/null
    }

    # restore caddy
    if [[ -f "$profile_dir/$name/Caddyfile" ]]; then
        cp -f "$profile_dir/$name/Caddyfile" "$is_caddyfile"
        [[ -d "$profile_dir/$name/caddy_conf" ]] && {
            rm -rf "$is_caddy_conf"
            cp -rf "$profile_dir/$name/caddy_conf" "$is_caddy_conf"
        }
    fi

    # restart
    manage restart &
    [[ $is_caddy ]] && manage restart caddy &

    _bright ">> switched to profile: $name"
}

profile_delete() {
    local name=$1
    [[ ! $name ]] && err "usage: sbx profile delete <name>"
    # 安全：拒絕路徑穿越
    [[ ! $name =~ ^[a-zA-Z0-9_\-]+$ ]] && err "profile name 含不允許的字符（僅字母數字 _-）"
    [[ ! -d "$profile_dir/$name" ]] && err "profile '$name' not found"

    echo -ne " ${c_red}delete profile '$name'? [y/N]:${c_none} "
    read -r confirm
    [[ "${confirm,,}" != "y" ]] && { _dim ">> cancelled"; return; }

    rm -rf "$profile_dir/$name"
    _bright ">> profile deleted: $name"
}
