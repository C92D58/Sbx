# check.sh — 健康檢查
#   sbx check              所有 config 健康檢查
#   sbx check <name>       指定 config

check_set() {
    if [[ $1 ]]; then
        check_config $1
    else
        check_all
    fi
}

check_config() {
    local name=$1
    local config_file=$is_conf_dir/$name.json
    [[ ! -f $config_file ]] && err "config $name not found"

    local port=$(jq -r '.inbounds[0].listen_port // 0' "$config_file")
    local proto=$(jq -r '.inbounds[0].type // "?"' "$config_file")

    # 1) file validity
    local file_ok=$($is_core_bin check -c "$config_file" 2>/dev/null && echo 1 || echo 0)

    # 2) port listening
    local port_ok=0
    ss -tlnp 2>/dev/null | grep -q ":$port " && port_ok=1

    # 3) core running
    local core_ok=0
    pgrep -f $is_core_bin >/dev/null 2>&1 && core_ok=1

    _dim ">> $name ($proto :$port)"
    printf "  %-20s %s\n" "$L_CHECK_FILE"  "$(status_icon $file_ok)"
    printf "  %-20s %s\n" "$L_CHECK_PORT"  "$(status_icon $port_ok)"
    printf "  %-20s %s\n" "$L_CHECK_CORE"  "$(status_icon $core_ok)"

    if [[ $file_ok == 1 && $port_ok == 1 && $core_ok == 1 ]]; then
        msg "  $(_bright ">> $L_CHECK_ALL_OK")"
    fi
}

check_all() {
    _dim ">> $L_CHECK_HEALTH"
    for f in $(ls $is_conf_dir/*.json 2>/dev/null); do
        local name=$(basename $f .json)
        check_config $name
    done
}

status_icon() {
    [[ $1 == 1 ]] && _bright "$L_OK" || _dim "$L_FAIL"
}
