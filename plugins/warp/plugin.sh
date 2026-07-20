#!/bin/bash
# Plugin: Cloudflare WARP — route traffic through WARP
#   sbx plugin warp setup     install & configure WARP
#   sbx plugin warp start     enable WARP outbound
#   sbx plugin warp stop      disable WARP outbound
#   sbx plugin warp status    show WARP connection status

PLUGIN_WARP_VER="1.0.0"
PLUGIN_WARP_DIR="/etc/sbx/plugins/warp"
PLUGIN_WARP_CONF="$PLUGIN_WARP_DIR/warp.conf"
PLUGIN_WARP_JSON="$PLUGIN_WARP_DIR/warp.json"

plugin_info() {
    echo "warp|${PLUGIN_WARP_VER}|Cloudflare WARP — route traffic through WARP"
}

plugin_init() {
    :
}

# ── Setup ──────────────────────────────────────────────────────
_warp_setup() {
    echo
    _bright "  ▐▌ Cloudflare WARP Setup"
    _dim   "  ▐▌ route traffic through WARP (WireGuard mode)"
    echo

    # Check dependencies
    local deps_ok=1
    for dep in wg curl jq; do
        if ! type -P "$dep" &>/dev/null; then
            echo -e "  ${c_red}✗${c_none} ${c_dim}$dep${c_none} — not installed"
            deps_ok=0
        else
            echo -e "  ${c_bright}✓${c_none} ${c_dim}$dep${c_none}"
        fi
    done

    [[ $deps_ok -eq 0 ]] && {
        echo
        echo -ne "  ${c_dim}install missing packages? [Y/n]:${c_none} "
        read -r yn
        [[ "${yn,,}" != "n" ]] && {
            $cmd install -y wireguard-tools curl 2>/dev/null || $cmd install -y wireguard curl 2>/dev/null
        }
    }

    mkdir -p "$PLUGIN_WARP_DIR"

    # Download and run wgcf to register
    local wgcf_bin="$PLUGIN_WARP_DIR/wgcf"
    if [[ ! -f "$wgcf_bin" ]]; then
        _dim ">> downloading wgcf..."
        local wgcf_url
        case $(uname -m) in
            amd64|x86_64) wgcf_url="https://github.com/ViRb3/wgcf/releases/latest/download/wgcf_2.2.22_linux_amd64" ;;
            *aarch64*|*armv8*) wgcf_url="https://github.com/ViRb3/wgcf/releases/latest/download/wgcf_2.2.22_linux_arm64" ;;
            *) err "unsupported arch for WARP" ;;
        esac
        _wget -q -O "$wgcf_bin" "$wgcf_url" && chmod +x "$wgcf_bin" || err "failed to download wgcf"
    fi

    # Register and generate config
    _dim ">> registering WARP account..."
    cd "$PLUGIN_WARP_DIR"

    if [[ ! -f "$PLUGIN_WARP_DIR/wgcf-account.toml" ]]; then
        $wgcf_bin register --accept-tos 2>/dev/null || {
            warn "WARP registration failed"
            return
        }
    fi

    if [[ ! -f "$PLUGIN_WARP_DIR/wgcf-profile.conf" ]]; then
        $wgcf_bin generate 2>/dev/null || {
            warn "WARP profile generation failed"
            return
        }
    fi

    # Parse WireGuard config into sing-box outbound JSON
    local wg_conf="$PLUGIN_WARP_DIR/wgcf-profile.conf"
    local private_key=$(awk '/PrivateKey/{print $3}' "$wg_conf")
    local address=$(awk '/Address/{print $3}' "$wg_conf")
    local endpoint=$(awk '/Endpoint/{print $2}' "$wg_conf" | head -1)
    local public_key=$(awk '/PublicKey/{print $3}' "$wg_conf" | head -1)

    jq -n \
        --arg tag "warp" \
        --arg type "wireguard" \
        --arg server "$(echo $endpoint | cut -d: -f1)" \
        --arg server_port "$(echo $endpoint | cut -d: -f2)" \
        --arg private_key "$private_key" \
        --arg peer_public_key "$public_key" \
        --arg address "$address" \
        '{
            type: "wireguard",
            tag: "warp",
            server: $server,
            server_port: ($server_port | tonumber),
            private_key: $private_key,
            peers: [{
                public_key: $peer_public_key,
                allowed_ips: ["0.0.0.0/0"],
                endpoint: $server + ":" + $server_port
            }],
            local_address: [$address]
        }' > "$PLUGIN_WARP_JSON"

    echo "WARP_ENABLED=1" > "$PLUGIN_WARP_CONF"

    _bright ">> WARP configured"
    echo -e "  ${c_dim}endpoint:${c_none} ${c_bright}${endpoint}${c_none}"
    echo -e "  ${c_dim}address:${c_none}  ${c_bright}${address}${c_none}"
    echo
    echo -e "  ${c_dim}enable:${c_none}  sbx plugin warp start"
    echo -e "  ${c_dim}test:${c_none}    curl --interface warp ifconfig.me"
}

# ── Start / Enable ─────────────────────────────────────────────
_warp_start() {
    [[ ! -f "$PLUGIN_WARP_JSON" ]] && {
        warn "WARP not configured. Run: sbx plugin warp setup"
        return
    }

    # Add WARP outbound to config.json
    local warp_outbound=$(cat "$PLUGIN_WARP_JSON")

    if jq -e '.outbounds | any(.tag == "warp")' "$is_config_json" >/dev/null 2>&1; then
        _dim ">> WARP outbound already exists"
    else
        jq --argjson warp "$warp_outbound" \
            '.outbounds += [$warp]' \
            "$is_config_json" >"$is_config_json.tmp" \
            && mv "$is_config_json.tmp" "$is_config_json"
    fi

    echo "WARP_ENABLED=1" > "$PLUGIN_WARP_CONF"
    manage restart &
    _bright ">> WARP enabled — restarting sing-box"
}

# ── Stop / Disable ─────────────────────────────────────────────
_warp_stop() {
    if jq -e '.outbounds | any(.tag == "warp")' "$is_config_json" >/dev/null 2>&1; then
        jq 'del(.outbounds[] | select(.tag == "warp"))' \
            "$is_config_json" >"$is_config_json.tmp" \
            && mv "$is_config_json.tmp" "$is_config_json"
        echo "WARP_ENABLED=0" > "$PLUGIN_WARP_CONF"
        manage restart &
        _bright ">> WARP disabled — restarting sing-box"
    else
        _dim ">> WARP already disabled"
    fi
}

# ── Status ─────────────────────────────────────────────────────
_warp_status() {
    echo
    _bright "  ▐▌ Cloudflare WARP"
    echo

    if [[ -f "$PLUGIN_WARP_CONF" ]]; then
        . "$PLUGIN_WARP_CONF"
        local status_icon="${c_dim}disabled${c_none}"
        [[ "$WARP_ENABLED" == "1" ]] && status_icon="${c_bright}enabled${c_none}"
        echo -e "  ${c_dim}status:${c_none}   $status_icon"
    else
        echo -e "  ${c_dim}status:${c_none}   ${c_dim}not configured${c_none}"
    fi

    if [[ -f "$PLUGIN_WARP_DIR/wgcf-profile.conf" ]]; then
        local ep=$(awk '/Endpoint/{print $2; exit}' "$PLUGIN_WARP_DIR/wgcf-profile.conf")
        local addr=$(awk '/Address/{print $3; exit}' "$PLUGIN_WARP_DIR/wgcf-profile.conf")
        echo -e "  ${c_dim}endpoint:${c_none} ${c_bright}$ep${c_none}"
        echo -e "  ${c_dim}address:${c_none}  ${c_bright}$addr${c_none}"
    fi

    # Test WARP connectivity
    if jq -e '.outbounds | any(.tag == "warp")' "$is_config_json" >/dev/null 2>&1; then
        echo -e "  ${c_dim}outbound:${c_none} ${c_bright}configured in sing-box${c_none}"
    fi

    echo
}

# ── Plugin Entry ───────────────────────────────────────────────
warp_main() {
    case "${1,,}" in
        setup|install|config) _warp_setup ;;
        start|enable|on)      _warp_start ;;
        stop|disable|off)     _warp_stop ;;
        status|info)          _warp_status ;;
        *)
            echo
            _bright "  ▐▌ Cloudflare WARP v${PLUGIN_WARP_VER}"
            _dim   "  ▐▌ route traffic through WARP (WireGuard mode)"
            echo
            echo -e "  ${c_dim}commands:${c_none}"
            echo -e "  ${c_bright}setup${c_none}   — install & configure WARP"
            echo -e "  ${c_bright}start${c_none}   — enable WARP outbound"
            echo -e "  ${c_bright}stop${c_none}    — disable WARP outbound"
            echo -e "  ${c_bright}status${c_none}  — show WARP status"
            echo
            _warp_status
            ;;
    esac
}
