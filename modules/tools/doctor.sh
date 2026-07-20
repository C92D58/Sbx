# doctor.sh — system diagnostics
#   sbx doctor    run full system health diagnostics

doctor_run() {
    echo
    _bright "  ▐▌ sbx doctor"
    _dim   "  ▐▌ system diagnostics"
    echo

    local all_pass=1
    local checks=0
    local passed=0

    doctor_check() {
        local label="$1"
        local result="$2"
        local ok="$3"
        ((checks++))
        if [[ "$ok" == "1" ]]; then
            printf "  ${c_dim}%-20s${c_none} ${c_bright}%s${c_none}\n" "$label" "$result"
            ((passed++))
        else
            printf "  ${c_dim}%-20s${c_none} ${c_red}%s${c_none}\n" "$label" "$result"
            all_pass=0
        fi
    }

    # 1) Kernel version
    local kern_major=$(uname -r | cut -d. -f1)
    local kern_minor=$(uname -r | cut -d. -f2)
    local kern_ver=$(uname -r)
    if [[ $kern_major -gt 4 ]] || [[ $kern_major -eq 4 && $kern_minor -ge 9 ]]; then
        doctor_check "Kernel" "$kern_ver" 1
    else
        doctor_check "Kernel" "$kern_ver (need 4.9+)" 0
    fi

    # 2) System time (NTP)
    if [[ $is_systemd ]]; then
        local ntp_sync=$(timedatectl show -p NTPSynchronized 2>/dev/null | cut -d= -f2)
        if [[ "$ntp_sync" == "yes" ]]; then
            doctor_check "System Time" "synced" 1
        else
            doctor_check "System Time" "not synced" 0
        fi
    else
        doctor_check "System Time" "unknown (no systemd)" 1
    fi

    # 3) BBR
    local tcp_cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [[ "$tcp_cc" == "bbr" ]]; then
        doctor_check "BBR" "enabled" 1
    else
        doctor_check "BBR" "$tcp_cc" 0
    fi

    # 4) Firewall — check if iptables has rules that might block
    local fw_status="open"
    local fw_ok=1
    if type -P iptables &>/dev/null; then
        local fw_rules=$(iptables -L INPUT -n 2>/dev/null | grep -c 'DROP\|REJECT' || echo 0)
        if [[ $fw_rules -gt 10 ]]; then
            fw_status="restrictive ($fw_rules rules)"
            fw_ok=0
        fi
    else
        fw_status="no iptables"
    fi
    doctor_check "Firewall" "$fw_status" $fw_ok

    # 5) TLS certificate validity
    if [[ -f "$is_tls_cer" ]]; then
        local cert_end=$(openssl x509 -enddate -noout -in "$is_tls_cer" 2>/dev/null | cut -d= -f2)
        if [[ $cert_end ]]; then
            local cert_epoch=$(date -d "$cert_end" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$cert_end" +%s 2>/dev/null)
            local now_epoch=$(date +%s)
            if [[ $cert_epoch -gt $now_epoch ]]; then
                doctor_check "Certificate" "valid" 1
            else
                doctor_check "Certificate" "expired" 0
            fi
        else
            doctor_check "Certificate" "self-signed" 1
        fi
    else
        doctor_check "Certificate" "none" 0
    fi

    # 6) Port check (is sing-box port listening?)
    local sb_ports=$(ss -tlnp 2>/dev/null | grep -c "$is_core_bin" || echo 0)
    if [[ $sb_ports -gt 0 ]]; then
        doctor_check "Port" "$sb_ports listening" 1
    else
        doctor_check "Port" "no ports" 0
    fi

    # 7) DNS resolution
    if host -W2 google.com &>/dev/null || nslookup google.com &>/dev/null; then
        doctor_check "DNS" "resolving" 1
    else
        doctor_check "DNS" "failed" 0
    fi

    # 8) sing-box process
    if pgrep -f "$is_core_bin" &>/dev/null; then
        doctor_check "sing-box" "running" 1
    else
        doctor_check "sing-box" "stopped" 0
    fi

    echo
    if [[ $all_pass -eq 1 ]]; then
        _bright "  >> Your server is healthy."
    else
        local score=$(( passed * 100 / checks ))
        warn "  >> $passed/$checks checks passed ($score%) — review items above"
    fi
    echo
}
