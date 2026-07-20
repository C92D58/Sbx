# speed.sh — 测速
#   sbx speed vps         VPS 總頻寬测速
#   sbx speed <name>      指定 config 测速
#   sbx speed             全测

speed_set() {
    case ${1,,} in
    vps)
        speed_test_vps
        ;;
    *)
        if [[ $1 ]]; then
            speed_test_config $1
        else
            speed_test_all
        fi
        ;;
    esac
}

speed_test_vps() {
    _dim ">> $L_SPEED_VPS"
    local url="https://speed.cloudflare.com/__down?bytes=1048576"
    msg "  $L_SPEED_DOWNLOAD"
    local result=$(curl -o /dev/null -s -w "%{speed_download}" "$url" 2>/dev/null)
    if [[ ! $result || $result == "0" ]]; then
        _dim "[-] download failed"
        return
    fi
    # fallback if bc not available
    if type -P bc &>/dev/null; then
        local mbps=$(echo "scale=1; $result * 8 / 1000000" | bc)
    else
        local mbps=$(( result * 8 / 1000000 ))
    fi
    msg "  $(_bright "${mbps} Mbps")"
}

speed_test_config() {
    local name=$1
    local config_file=$is_conf_dir/$name.json
    [[ ! -f $config_file ]] && err "config $name not found"

    local port=$(jq -r '.inbounds[0].listen_port // 0' "$config_file")
    local proto=$(jq -r '.inbounds[0].type // "?"' "$config_file")

    _dim ">> $name ($proto :$port)"
    # port connectivity
    if ss -tlnp 2>/dev/null | grep -q ":$port "; then
        msg "  $L_SPEED_PORT $(_bright "$L_SPEED_OPEN")"
    else
        msg "  $L_SPEED_PORT $(_dim "$L_SPEED_CLOSED")"
    fi
    # vps speed
    speed_test_vps
}

speed_test_all() {
    for f in $(ls $is_conf_dir/*.json 2>/dev/null); do
        local name=$(basename $f .json)
        speed_test_config $name
    done
}
