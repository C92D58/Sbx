# check.sh — health check with scoring
#   sbx check               all config health check
#   sbx check <name>        specific config

check_set() {
    if [[ $1 ]]; then
        check_config $1
    else
        check_all
    fi
}

# star rating
_stars() {
    local n=$1
    local out=""
    for ((i=0; i<n; i++)); do
        out+="${c_bright}★${c_none}"
    done
    for ((i=n; i<5; i++)); do
        out+="${c_dim}☆${c_none}"
    done
    echo -ne "$out"
}

check_config() {
    local name=$1
    local config_file=$is_conf_dir/$name.json
    [[ ! -f $config_file ]] && err "config $name not found"

    local port=$(jq -r '.inbounds[0].listen_port // 0' "$config_file")
    local proto=$(jq -r '.inbounds[0].type // "?"' "$config_file")

    # checks: file, port, core, dns, tls
    local file_ok=0 port_ok=0 core_ok=0 dns_ok=0 tls_ok=0

    # 1) file validity
    $is_core_bin check -c "$config_file" &>/dev/null && file_ok=1

    # 2) port listening
    ss -tlnp 2>/dev/null | grep -q ":$port " && port_ok=1

    # 3) core running
    pgrep -f "$is_core_bin" >/dev/null 2>&1 && core_ok=1

    # 4) DNS resolving
    host -W2 google.com &>/dev/null || nslookup google.com &>/dev/null && dns_ok=1

    # 5) TLS cert
    if [[ -f "$is_tls_cer" ]]; then
        local cert_end=$(openssl x509 -enddate -noout -in "$is_tls_cer" 2>/dev/null | cut -d= -f2)
        if [[ $cert_end ]]; then
            local cert_epoch=$(date -d "$cert_end" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$cert_end" +%s 2>/dev/null)
            local now_epoch=$(date +%s)
            [[ $cert_epoch -gt $now_epoch ]] && tls_ok=1
        fi
    else
        tls_ok=1  # no TLS needed
    fi

    local total=$(( file_ok + port_ok + core_ok + dns_ok + tls_ok ))
    local score=$(( total * 20 ))  # 5 checks × 20 each = max 100

    _dim ">> $name ($proto :$port)"
    echo -e "  Health: ${c_bright}$score/100${c_none} $(_stars $total)"
    echo
    printf "  ${c_dim}%-20s${c_none} %s\n" "$L_CHECK_FILE"  "$(status_icon $file_ok)"
    printf "  ${c_dim}%-20s${c_none} %s\n" "$L_CHECK_PORT"  "$(status_icon $port_ok)"
    printf "  ${c_dim}%-20s${c_none} %s\n" "$L_CHECK_CORE"  "$(status_icon $core_ok)"
    printf "  ${c_dim}%-20s${c_none} %s\n" "DNS"           "$(status_icon $dns_ok)"
    printf "  ${c_dim}%-20s${c_none} %s\n" "TLS"           "$(status_icon $tls_ok)"

    if [[ $total -eq 5 ]]; then
        msg "  $(_bright ">> $L_CHECK_ALL_OK")"
    fi
}

check_all() {
    _dim ">> $L_CHECK_HEALTH"
    echo
    for f in $(ls "$is_conf_dir"/*.json 2>/dev/null); do
        local name=$(basename "$f" .json)
        check_config "$name"
    done
}

status_icon() {
    [[ $1 == 1 ]] && echo -e "${c_bright}★★★★★${c_none}" || echo -e "${c_dim}☆☆☆☆☆${c_none}"
}
