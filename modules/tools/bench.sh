# bench.sh — protocol latency benchmark
#   sbx bench                test all configs
#   sbx bench <name>         test specific config

bench_run() {
    echo
    _bright "  ▐▌ sbx bench"
    _dim   "  ▐▌ protocol latency benchmark"
    echo

    local targets=()

    if [[ $1 ]]; then
        # Specific config
        local config_file="$is_conf_dir/$1.json"
        [[ -f "$config_file" ]] || err "config $1 not found"
        targets=("$1")
    else
        # All configs
        for f in "$is_conf_dir"/*.json; do
            [[ -f "$f" ]] || continue
            targets+=("$(basename "$f" .json)")
        done
        [[ ${#targets[@]} -eq 0 ]] && err "no configs found"
    fi

    printf "  ${c_dim}%-10s %-8s %-8s %s${c_none}\n" "CONFIG" "PROTO" "PORT" "LATENCY"
    echo   "  ${c_dim}----------------------------------------${c_none}"

    local best_latency=999999
    local best_config=""

    for name in "${targets[@]}"; do
        local config_file="$is_conf_dir/$name.json"
        local port=$(jq -r '.inbounds[0].listen_port // 0' "$config_file")
        local proto=$(jq -r '.inbounds[0].type // "?"' "$config_file")

        # TCP connect timing
        local start=$(date +%s%N 2>/dev/null || echo 0)
        if timeout 2 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            local end=$(date +%s%N 2>/dev/null || echo 0)
            if [[ $start -gt 0 && $end -gt 0 ]]; then
                local latency=$(( (end - start) / 1000000 ))  # ms
            else
                local latency="--"
            fi
            printf "  ${c_bright}%-10s${c_none} ${c_dim}%-8s${c_none} %-8s ${c_bright}%s${c_none} ms\n" \
                "$name" "$proto" ":$port" "$latency"

            if [[ $latency != "--" && $latency -lt $best_latency ]]; then
                best_latency=$latency
                best_config="$name ($proto :$port)"
            fi
        else
            printf "  ${c_dim}%-10s %-8s %-8s %s${c_none}\n" \
                "$name" "$proto" ":$port" "timeout"
        fi
    done

    echo
    if [[ $best_config ]]; then
        _bright "  >> Recommended: $best_config ($best_latency ms)"
    fi
    echo
}
