# traffic.sh — 流量統計
#   sbx traffic              顯示所有 config 的連接数
#   sbx traffic <name>       顯示指定 config

traffic_set() {
    if [[ $1 ]]; then
        traffic_config $1
    else
        traffic_all
    fi
}

traffic_config() {
    local name=$1
    local config_file=$is_conf_dir/$name.json
    [[ ! -f $config_file ]] && err "config $name not found"

    local port=$(jq -r '.inbounds[0].listen_port // 0' "$config_file")
    local proto=$(jq -r '.inbounds[0].type // "?"' "$config_file")
    local conns=$(ss -tnp 2>/dev/null | grep -c ":$port " || echo 0)

    printf "  %-8s %-6s %-6s %s\n" "$name" "$proto" ":$port" "$(_bright "$conns")"
}

traffic_all() {
    _dim ">> $L_TRAFFIC_TITLE"
    printf "  %-8s %-6s %-6s %s\n" "$L_TRAFFIC_CONFIG" "$L_TRAFFIC_PROTO" "$L_TRAFFIC_PORT" "$L_TRAFFIC_CONNS"
    for f in $(ls $is_conf_dir/*.json 2>/dev/null); do
        local name=$(basename $f .json)
        traffic_config $name
    done
}
