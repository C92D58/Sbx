#!/bin/bash
# Plugin: NextDNS — advanced configuration wizard
#   sbx plugin nextdns setup      interactive setup wizard
#   sbx plugin nextdns profiles    manage NextDNS profiles
#   sbx plugin nextdns status      show DNS configuration
#   sbx plugin nextdns logs        view NextDNS analytics URL

PLUGIN_NEXTDNS_VER="1.0.0"
PLUGIN_NEXTDNS_CONF="/etc/sbx/plugins/nextdns.conf"

plugin_info() {
    echo "nextdns|${PLUGIN_NEXTDNS_VER}|NextDNS — advanced DNS configuration wizard"
}

plugin_init() {
    :
}

# ── Interactive Setup Wizard ───────────────────────────────────
_nextdns_setup() {
    echo
    _bright "  ▐▌ NextDNS Setup Wizard"
    _dim   "  ▐▌ advanced DNS configuration"
    echo

    # Step 1: Config ID
    echo -e "  ${c_dim}Step 1:${c_none} Your NextDNS Config ID"
    echo -e "  ${c_dim}        (find it at https://my.nextdns.io)${c_none}"
    echo
    echo -ne "  ${c_dim}Config ID:${c_none} "
    read -r ndns_id
    [[ ! $ndns_id ]] && { warn "Config ID required"; return; }

    # Step 2: Device name
    echo
    echo -e "  ${c_dim}Step 2:${c_none} Device name (optional)"
    echo -e "  ${c_dim}        (identifies this server in NextDNS logs)${c_none}"
    echo
    echo -ne "  ${c_dim}Device name [$(hostname 2>/dev/null || echo vps)]:${c_none} "
    read -r ndns_device
    [[ ! $ndns_device ]] && ndns_device=$(hostname 2>/dev/null || echo "vps")

    # Step 3: DNS protocol
    echo
    echo -e "  ${c_dim}Step 3:${c_none} DNS protocol"
    echo
    echo -e "  [1] ${c_bright}HTTPS (DoH)${c_none}    — recommended, works everywhere"
    echo -e "  [2] ${c_dim}QUIC${c_none}           — lowest latency"
    echo -e "  [3] ${c_dim}TLS${c_none}            — traditional DNS-over-TLS"
    echo
    echo -ne "  ${c_dim}protocol [1]:${c_none} "
    read -r ndns_proto_choice

    case $ndns_proto_choice in
        2) ndns_proto="quic" ;;
        3) ndns_proto="tls" ;;
        *) ndns_proto="https" ;;
    esac

    # Step 4: Fallback DNS
    echo
    echo -e "  ${c_dim}Step 4:${c_none} Fallback DNS servers"
    echo
    echo -e "  [1] ${c_bright}Cloudflare + Google${c_none}  — recommended"
    echo -e "  [2] ${c_dim}Cloudflare only${c_none}"
    echo -e "  [3] ${c_dim}Google only${c_none}"
    echo -e "  [4] ${c_dim}None${c_none}                    — NextDNS only"
    echo
    echo -ne "  ${c_dim}fallback [1]:${c_none} "
    read -r ndns_fallback

    # Step 5: Blocking preferences
    echo
    echo -e "  ${c_dim}Step 5:${c_none} Quick blocking presets"
    echo
    echo -e "  [1] ${c_bright}Balanced${c_none}       — ads + trackers"
    echo -e "  [2] ${c_dim}Strict${c_none}          — ads + trackers + malware + phishing"
    echo -e "  [3] ${c_dim}Minimal${c_none}         — malware only"
    echo -e "  [4] ${c_dim}Custom${c_none}          — configure at my.nextdns.io"
    echo
    echo -ne "  ${c_dim}preset [1]:${c_none} "
    read -r ndns_block

    # Save configuration
    mkdir -p "$(dirname "$PLUGIN_NEXTDNS_CONF")"
    cat > "$PLUGIN_NEXTDNS_CONF" <<EOF
# NextDNS configuration
NEXTDNS_ID="$ndns_id"
NEXTDNS_DEVICE="$ndns_device"
NEXTDNS_PROTO="$ndns_proto"
NEXTDNS_FALLBACK="$ndns_fallback"
EOF

    echo
    _bright "  >> Configuration saved"
    echo
    echo -e "  ${c_dim}apply now? [Y/n]:${c_none} "
    read -r apply
    [[ "${apply,,}" != "n" ]] && {
        # Apply DNS via the existing dns module
        load dns.sh
        dns_set_nextdns "$ndns_id" "$ndns_device"
        _bright "  >> NextDNS applied!"
    }

    echo
    echo -e "  ${c_dim}────────────────────────────${c_none}"
    echo -e "  ${c_bright}Dashboard:${c_none} https://my.nextdns.io/${ndns_id}/logs"
    echo -e "  ${c_bright}Analytics:${c_none} https://my.nextdns.io/${ndns_id}/analytics"
    echo -e "  ${c_dim}────────────────────────────${c_none}"
    echo
}

# ── Profile Management ─────────────────────────────────────────
_nextdns_profiles() {
    echo
    _bright "  ▐▌ NextDNS Profiles"
    echo

    if [[ -f "$PLUGIN_NEXTDNS_CONF" ]]; then
        . "$PLUGIN_NEXTDNS_CONF"
        echo -e "  ${c_dim}────────────────────────────${c_none}"
        echo -e "  ${c_dim}Config ID:${c_none}  ${c_bright}${NEXTDNS_ID}${c_none}"
        echo -e "  ${c_dim}Device:${c_none}     ${c_bright}${NEXTDNS_DEVICE}${c_none}"
        echo -e "  ${c_dim}Protocol:${c_none}   ${c_bright}${NEXTDNS_PROTO}${c_none}"
        echo -e "  ${c_dim}Fallback:${c_none}   ${c_bright}${NEXTDNS_FALLBACK}${c_none}"
        echo -e "  ${c_dim}────────────────────────────${c_none}"
    else
        echo -e "  ${c_dim}no profile configured${c_none}"
        echo -e "  ${c_dim}run:${c_none} sbx plugin nextdns setup"
    fi

    echo
    echo -e "  ${c_dim}────────────────────────────${c_none}"
    echo -e "  ${c_bright}Dashboard:${c_none} https://my.nextdns.io"
    echo -e "  ${c_dim}────────────────────────────${c_none}"
    echo
}

# ── Current DNS Status ─────────────────────────────────────────
_nextdns_status() {
    echo
    _bright "  ▐▌ DNS Status"
    echo

    # Show current DNS config from sing-box
    local dns_config=$(jq -r '.dns' "$is_config_json" 2>/dev/null)

    if [[ $dns_config && $dns_config != "null" && $dns_config != "{}" ]]; then
        echo -e "  ${c_bright}DNS configured ✓${c_none}"
        echo

        # Show servers
        local server_count=$(jq -r '.dns.servers | length // 0' "$is_config_json" 2>/dev/null)
        echo -e "  ${c_dim}servers:${c_none} ${c_bright}${server_count}${c_none}"

        jq -r '.dns.servers[]? | "  \(.tag // "?") -> \(.type // "?")  \(.server // .address // "local")"' \
            "$is_config_json" 2>/dev/null | while IFS= read -r line; do
                echo -e "  ${c_dim}$line${c_none}"
            done

        echo
        local final_dns=$(jq -r '.dns.final // "none"' "$is_config_json" 2>/dev/null)
        echo -e "  ${c_dim}final:${c_none} ${c_bright}${final_dns}${c_none}"

        local strategy=$(jq -r '.dns.strategy // "default"' "$is_config_json" 2>/dev/null)
        echo -e "  ${c_dim}strategy:${c_none} ${c_bright}${strategy}${c_none}"
    else
        echo -e "  ${c_dim}no DNS configured${c_none}"
        echo -e "  ${c_dim}run:${c_none} sbx dns cf"
        echo -e "  ${c_dim}or:${c_none}   sbx plugin nextdns setup"
    fi

    # DNS resolution test
    echo
    _dim "  >> DNS resolution test"
    for test_domain in google.com cloudflare.com github.com; do
        local result
        if host -W2 "$test_domain" &>/dev/null; then
            result="${c_bright}✓${c_none}"
        else
            result="${c_red}✗${c_none}"
        fi
        echo -e "  $result ${c_dim}${test_domain}${c_none}"
    done

    echo
}

# ── Analytics URL ──────────────────────────────────────────────
_nextdns_logs() {
    echo
    _bright "  ▐▌ NextDNS Analytics"
    echo

    if [[ -f "$PLUGIN_NEXTDNS_CONF" ]]; then
        . "$PLUGIN_NEXTDNS_CONF"
        echo -e "  ${c_dim}────────────────────────────${c_none}"
        echo -e "  ${c_bright}Logs:${c_none}      https://my.nextdns.io/${NEXTDNS_ID}/logs"
        echo -e "  ${c_bright}Analytics:${c_none} https://my.nextdns.io/${NEXTDNS_ID}/analytics"
        echo -e "  ${c_bright}Settings:${c_none}  https://my.nextdns.io/${NEXTDNS_ID}/setup"
        echo -e "  ${c_dim}────────────────────────────${c_none}"
        echo
        echo -e "  ${c_dim}Device:${c_none} ${c_bright}${NEXTDNS_DEVICE}${c_none}"
        echo -e "  ${c_dim}Proto:${c_none}  ${c_bright}${NEXTDNS_PROTO}${c_none}"
    else
        echo -e "  ${c_dim}not configured. Run:${c_none} sbx plugin nextdns setup"
    fi

    echo
}

# ── Plugin Entry ───────────────────────────────────────────────
nextdns_main() {
    case "${1,,}" in
        setup|wizard|config)   _nextdns_setup ;;
        profiles|profile|list) _nextdns_profiles ;;
        status|check)         _nextdns_status ;;
        logs|analytics|url)   _nextdns_logs ;;
        *)
            echo
            _bright "  ▐▌ NextDNS v${PLUGIN_NEXTDNS_VER}"
            _dim   "  ▐▌ advanced DNS configuration wizard"
            echo
            echo -e "  ${c_dim}commands:${c_none}"
            echo -e "  ${c_bright}setup${c_none}     — interactive setup wizard"
            echo -e "  ${c_bright}profiles${c_none}  — view saved profiles"
            echo -e "  ${c_bright}status${c_none}    — show DNS configuration"
            echo -e "  ${c_bright}logs${c_none}      — show analytics URLs"
            echo
            _nextdns_status
            ;;
    esac
}
