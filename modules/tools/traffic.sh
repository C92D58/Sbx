# traffic.sh — 流量統計
#   透過 sing-box Clash API (/traffic streaming) 讀取即時上傳/下載速率
#   sbx traffic              即時速率 + 各 config 連線數
#   sbx traffic <name>       顯示指定 config

IS_CLASH_API="127.0.0.1:9090"
IS_CLASH_SECRET="sbx"

# ── 讀取 Clash API /traffic（streaming，取最後一筆 = 當前速率）──
clash_traffic() {
    # /traffic 每 0.5s 推送一筆 {"up":N,"down":N} bytes/s
    # 收集 1.8s 內所有筆，最後一筆即為當前速率
    timeout 1.8 curl -sN -H "Authorization: Bearer $IS_CLASH_SECRET" \
        "http://$IS_CLASH_API/traffic" 2>/dev/null \
        | tail -1
}

# ── 人類可讀格式 ─────────────────────────────────────────────
fmt_speed() {
    local bps=${1:-0}
    if [[ $bps -ge 1048576 ]]; then
        echo "$(awk "BEGIN{printf \"%.2f\", $bps/1048576}") MB/s"
    elif [[ $bps -ge 1024 ]]; then
        echo "$(awk "BEGIN{printf \"%.1f\", $bps/1024}") KB/s"
    else
        echo "${bps} B/s"
    fi
}

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
    _dim ">> 流量統計"
    echo

    # ── 即時速率（Clash API /traffic）──
    local tdata
    tdata=$(clash_traffic)
    if [[ ! $tdata || ! $(echo "$tdata" | jq -r '.up // "x"' 2>/dev/null | grep -v x) ]]; then
        _dim "  [!] Clash API 不可用 — 請先執行: sbx fix-config.json"
        echo
    else
        local up=$(echo "$tdata" | jq -r '.up // 0' 2>/dev/null)
        local down=$(echo "$tdata" | jq -r '.down // 0' 2>/dev/null)
        echo -e "  ${c_dim}上傳${c_none} ${c_bright}$(fmt_speed ${up:-0})${c_none}   ${c_dim}下載${c_none} ${c_bright}$(fmt_speed ${down:-0})${c_none}"
        echo
    fi

    # ── 各 config 連線數 ──
    printf "  %-8s %-6s %-6s %s\n" "$L_TRAFFIC_CONFIG" "$L_TRAFFIC_PROTO" "$L_TRAFFIC_PORT" "$L_TRAFFIC_CONNS"
    for f in $(ls $is_conf_dir/*.json 2>/dev/null); do
        local name=$(basename $f .json)
        traffic_config $name
    done
}
