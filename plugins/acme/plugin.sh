#!/bin/bash
# Plugin: ACME — SSL/TLS certificate management
#   sbx plugin acme setup      install acme.sh
#   sbx plugin acme issue <d>  issue certificate for domain
#   sbx plugin acme renew      renew all certificates
#   sbx plugin acme status     show certificate status

PLUGIN_ACME_VER="1.0.0"
PLUGIN_ACME_DIR="/etc/sbx/plugins/acme"
PLUGIN_ACME_SH="$PLUGIN_ACME_DIR/acme.sh/acme.sh"

plugin_info() {
    echo "acme|${PLUGIN_ACME_VER}|ACME — SSL/TLS certificate management"
}

plugin_init() {
    :
}

# ── Install acme.sh ────────────────────────────────────────────
_acme_install() {
    echo
    _bright "  ▐▌ ACME Setup"
    _dim   "  ▐▌ install acme.sh for certificate management"
    echo

    if [[ -f "$PLUGIN_ACME_SH" ]]; then
        _bright ">> acme.sh already installed"
        echo -e "  ${c_dim}path:${c_none} ${c_bright}$PLUGIN_ACME_SH${c_none}"
        return
    fi

    mkdir -p "$PLUGIN_ACME_DIR"

    _dim ">> downloading acme.sh..."
    local install_url="https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh"

    if _wget -q -O "$PLUGIN_ACME_DIR/acme.sh" "$install_url"; then
        chmod +x "$PLUGIN_ACME_DIR/acme.sh"
        # Set default CA to Let's Encrypt
        "$PLUGIN_ACME_DIR/acme.sh" --set-default-ca --server letsencrypt 2>/dev/null
        _bright ">> acme.sh installed"
        echo -e "  ${c_dim}path:${c_none} ${c_bright}$PLUGIN_ACME_DIR/acme.sh${c_none}"
        echo -e "  ${c_dim}CA:${c_none}    ${c_bright}Let's Encrypt${c_none}"
    else
        warn "failed to download acme.sh"
    fi
}

# ── Issue Certificate ──────────────────────────────────────────
_acme_issue() {
    local domain="$1"

    [[ ! -f "$PLUGIN_ACME_DIR/acme.sh" ]] && {
        warn "acme.sh not installed. Run: sbx plugin acme setup"
        return
    }

    [[ ! $domain ]] && {
        echo -ne " ${c_dim}domain:${c_none} "
        read -r domain
    }
    [[ ! $domain ]] && { warn "domain required"; return; }

    echo
    _dim ">> issuing certificate for: $domain"

    # Use standalone HTTP mode (port 80 must be free)
    # Stop Caddy temporarily if it's using port 80
    local caddy_was_running=0
    if [[ $is_caddy ]] && pgrep -f "$is_caddy_bin" &>/dev/null; then
        _dim ">> temporarily stopping Caddy..."
        manage stop caddy &>/dev/null
        sleep 1
        caddy_was_running=1
    fi

    # Issue cert
    local cert_home="$PLUGIN_ACME_DIR/certs"
    mkdir -p "$cert_home"

    "$PLUGIN_ACME_DIR/acme.sh" --issue \
        --standalone \
        -d "$domain" \
        --home "$cert_home" \
        --force 2>&1 | while IFS= read -r line; do
            echo -e "  ${c_dim}$line${c_none}"
        done

    local acme_rc=${PIPESTATUS[0]}

    # Restart Caddy if it was running
    [[ $caddy_was_running -eq 1 ]] && {
        _dim ">> restarting Caddy..."
        manage start caddy &>/dev/null
    }

    if [[ $acme_rc -eq 0 ]]; then
        local cert_path="$cert_home/${domain}"
        _bright ">> certificate issued!"
        echo
        echo -e "  ${c_dim}cert:${c_none} ${c_bright}${cert_path}/fullchain.cer${c_none}"
        echo -e "  ${c_dim}key:${c_none}  ${c_bright}${cert_path}/${domain}.key${c_none}"
        echo
        echo -e "  ${c_dim}copy to sing-box:${c_none}"
        echo -e "  ${c_bright}cp ${cert_path}/fullchain.cer /etc/sbx/bin/tls.cer${c_none}"
        echo -e "  ${c_bright}cp ${cert_path}/${domain}.key /etc/sbx/bin/tls.key${c_none}"
    else
        warn "certificate issuance failed — check that port 80 is free and DNS is correct"
    fi
}

# ── Renew All ──────────────────────────────────────────────────
_acme_renew() {
    [[ ! -f "$PLUGIN_ACME_DIR/acme.sh" ]] && {
        warn "acme.sh not installed. Run: sbx plugin acme setup"
        return
    }

    echo
    _dim ">> renewing all certificates..."

    local cert_home="$PLUGIN_ACME_DIR/certs"

    "$PLUGIN_ACME_DIR/acme.sh" --renew-all \
        --home "$cert_home" 2>&1 | while IFS= read -r line; do
            echo -e "  ${c_dim}$line${c_none}"
        done

    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        _bright ">> renewal complete"
    else
        warn "some renewals may have failed"
    fi
}

# ── Certificate Status ─────────────────────────────────────────
_acme_status() {
    echo
    _bright "  ▐▌ ACME Certificates"
    echo

    if [[ ! -f "$PLUGIN_ACME_DIR/acme.sh" ]]; then
        echo -e "  ${c_dim}acme.sh:${c_none} not installed"
        echo -e "  ${c_dim}install:${c_none} sbx plugin acme setup"
        echo
        return
    fi

    echo -e "  ${c_dim}acme.sh:${c_none} ${c_bright}installed${c_none}"

    local cert_home="$PLUGIN_ACME_DIR/certs"
    if [[ -d "$cert_home" ]]; then
        for d in "$cert_home"/*/; do
            [[ -d "$d" ]] || continue
            local domain=$(basename "$d")
            # Skip non-domain directories
            [[ "$domain" == "ca" || "$domain" == "http.header" ]] && continue

            local cert_file="$d/fullchain.cer"
            if [[ -f "$cert_file" ]]; then
                local enddate=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
                local cert_epoch=$(date -d "$enddate" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$enddate" +%s 2>/dev/null)
                local now_epoch=$(date +%s)
                local days_left=$(( (cert_epoch - now_epoch) / 86400 ))

                local status_icon="${c_bright}valid${c_none}"
                [[ $days_left -lt 30 ]] && status_icon="${c_red}expiring soon${c_none}"
                [[ $days_left -lt 0 ]] && status_icon="${c_red}expired${c_none}"

                printf "  ${c_bright}%-30s${c_none} ${c_dim}%s days${c_none}  %s\n" \
                    "$domain" "$days_left" "$status_icon"
            fi
        done
    else
        echo -e "  ${c_dim}no certificates issued yet${c_none}"
    fi

    # Check current sing-box cert
    echo
    if [[ -f "$is_tls_cer" ]]; then
        local sb_enddate=$(openssl x509 -enddate -noout -in "$is_tls_cer" 2>/dev/null | cut -d= -f2)
        echo -e "  ${c_dim}sing-box cert:${c_none} ${c_dim}$sb_enddate${c_none}"
    fi

    echo
}

# ── Plugin Entry ───────────────────────────────────────────────
acme_main() {
    case "${1,,}" in
        setup|install)       _acme_install ;;
        issue|create|new)    _acme_issue "$2" ;;
        renew|refresh)       _acme_renew ;;
        status|list|info)    _acme_status ;;
        *)
            echo
            _bright "  ▐▌ ACME Certificate Manager v${PLUGIN_ACME_VER}"
            _dim   "  ▐▌ SSL/TLS certificate management with acme.sh"
            echo
            echo -e "  ${c_dim}commands:${c_none}"
            echo -e "  ${c_bright}setup${c_none}       — install acme.sh"
            echo -e "  ${c_bright}issue <domain>${c_none} — issue certificate"
            echo -e "  ${c_bright}renew${c_none}       — renew all certificates"
            echo -e "  ${c_bright}status${c_none}      — show certificate status"
            echo
            _acme_status
            ;;
    esac
}
