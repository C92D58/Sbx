# dns.sh - DNS 配置模块
#
# CLI 用法:
#   sbx dns nextdns <config_id>    NextDNS (DoH) + Cloudflare/Google 備援
#   sbx dns cf                       Cloudflare H3
#   sbx dns gg                       Google H3
#   sbx dns 11 | 88 | family         預設單服務器
#   sbx dns set <address>            自定義 DNS
#   sbx dns none                     清除 DNS

is_dns_presets=(
    1.1.1.1
    8.8.8.8
    h3://cloudflare-dns.com/dns-query
    h3://family.cloudflare-dns.com/dns-query
    h3://dns.google/dns-query
)

# ── 主入口 ──────────────────────────────────────────────
dns_set() {
    # Detect core version for DNS format (v1.12+ uses new format)
    local core_ver=${is_core_ver#v}
    if [[ $(printf '%s\n' "1.12" "$core_ver" | sort -V | head -n1) == "1.12" ]]; then
        is_dns_new=1
    fi

    if [[ $1 ]]; then
        # ── CLI 模式 ──
        case ${1,,} in
        nextdns)
            dns_set_nextdns $2 $3
            return
            ;;
        11 | 1111)
            is_dns_use=${is_dns_presets[0]}
            ;;
        88 | 8888)
            is_dns_use=${is_dns_presets[1]}
            ;;
        gg | google)
            is_dns_use=${is_dns_presets[4]}
            ;;
        cf | cloudflare)
            is_dns_use=${is_dns_presets[2]}
            ;;
        nosex | family)
            is_dns_use=${is_dns_presets[3]}
            ;;
        set)
            if [[ $2 ]]; then
                is_dns_use=${2,,}
            else
                ask string is_dns_use "請輸入 DNS: "
            fi
            ;;
        none)
            is_dns_use=none
            ;;
        *)
            err "無法識別 DNS 參數: $@"
            ;;
        esac

        is_dns_use_bak=$is_dns_use
        if [[ $is_dns_use == "none" ]]; then
            dns_clear
        else
            dns_write_single "$is_dns_use"
        fi
    else
        # ── 互動選單 ──
        is_tmp_list=(
            "$L_DNS_NEXTDNS"
            "$L_DNS_CF"
            "$L_DNS_GG"
            "$L_DNS_11"
            "$L_DNS_88"
            "$L_DNS_FAMILY"
            "$L_DNS_CUSTOM"
            "$L_DNS_CLEAR"
        )
        ask list is_dns_pick null "\n$L_SELECT:\n"
        case $REPLY in
        1) dns_set_nextdns ; return ;;
        2) is_dns_use=${is_dns_presets[2]} ;;
        3) is_dns_use=${is_dns_presets[4]} ;;
        4) is_dns_use=${is_dns_presets[0]} ;;
        5) is_dns_use=${is_dns_presets[1]} ;;
        6) is_dns_use=${is_dns_presets[3]} ;;
        7) ask string is_dns_use "請輸入 DNS: " ;;
        8) is_dns_use=none ;;
        esac

        is_dns_use_bak=$is_dns_use
        if [[ $is_dns_use == "none" ]]; then
            dns_clear
        else
            dns_write_single "$is_dns_use"
        fi
    fi

    manage restart &
    msg "  $(_bright "$is_dns_use_bak")"
}

# ── NextDNS 多服務器配置 ──────────────────────────────
dns_set_nextdns() {
    local config_id=$1
    local device_name=$2

    # 互動獲取 Config ID
    if [[ ! $config_id ]]; then
        ask string config_id "$L_DNS_NEXTDNS_ID: "
    fi

    # 互動獲取裝置名稱 (選填)
    if [[ ! $device_name ]]; then
        echo -ne "  $L_DNS_DEVICE: "
        read -r device_name
    fi

    msg "  NextDNS (DoH${device_name:+ / $device_name}) + Cloudflare + Google"
    dns_write_nextdns "$config_id" "https" "$device_name"
    manage restart &
    msg "  $(_bright "NextDNS $config_id${device_name:+ ($device_name)}")"
}

# ── 生成 NextDNS 多服務器 JSON ──────────────────────
dns_write_nextdns() {
    local config_id=$1
    local protocol=$2
    local device_name=$3
    local config_file=$is_config_json

    # Build the DoH path: /CONFIG_ID or /CONFIG_ID/DEVICE_NAME
    local doh_path="/${config_id}"
    [[ $device_name ]] && doh_path="/${config_id}/${device_name}"

    # ── 建構 servers 数组 ──
    local servers='[]'

    # 1) NextDNS 主服務器
    local nextdns_entry
    case $protocol in
    quic)
        nextdns_entry=$(jq -n \
            --arg tag "nextdns" \
            --arg type "quic" \
            --arg server "${config_id}.dns.nextdns.io" \
            '{tag:$tag, type:$type, server:$server, server_port:853}')
        ;;
    tls)
        nextdns_entry=$(jq -n \
            --arg tag "nextdns" \
            --arg type "tls" \
            --arg server "${config_id}.dns.nextdns.io" \
            '{tag:$tag, type:$type, server:$server, server_port:853}')
        ;;
    *) # https (DoH)
        nextdns_entry=$(jq -n \
            --arg tag "nextdns" \
            --arg type "https" \
            --arg server "dns.nextdns.io" \
            --arg path "$doh_path" \
            '{tag:$tag, type:$type, server:$server, server_port:443, path:$path}')
        ;;
    esac
    servers=$(jq '. + [$a]' --argjson a "$nextdns_entry" <<<"$servers")

    # 2) Cloudflare H3 備援
    local cf_entry=$(jq -n \
        --arg tag "cloudflare" \
        --arg type "h3" \
        --arg server "cloudflare-dns.com" \
        '{tag:$tag, type:$type, server:$server, server_port:443}')
    servers=$(jq '. + [$a]' --argjson a "$cf_entry" <<<"$servers")

    # 3) Google H3 備援
    local gg_entry=$(jq -n \
        --arg tag "google" \
        --arg type "h3" \
        --arg server "dns.google" \
        '{tag:$tag, type:$type, server:$server, server_port:443}')
    servers=$(jq '. + [$a]' --argjson a "$gg_entry" <<<"$servers")

    # 4) Local 解析器
    servers=$(jq '. + [{"tag":"local","type":"local"}]' <<<"$servers")

    # ── rules: geosite-cn 走本地 DNS ──
    local rules='[{"rule_set":["geosite-cn"],"server":"local"}]'

    # ── 建構完整 DNS 配置 ──
    local dns_obj=$(jq -n \
        --argjson servers "$servers" \
        --argjson rules "$rules" \
        '{
            servers: $servers,
            rules: $rules,
            final: "nextdns",
            strategy: "prefer_ipv4",
            disable_cache: false,
            disable_expire: false
        }')

    # ── 写入 config.json ──
    jq --argjson dns "$dns_obj" '.dns = $dns | .route.default_domain_resolver = "nextdns"' \
        "$config_file" >"$config_file.tmp" && mv "$config_file.tmp" "$config_file"
}

# ── 單服務器配置 ──────────────────────
dns_write_single() {
    local addr=$1
    dns_set_server "$addr"

    if [[ $is_dns_new ]]; then
        jq \
            '.dns.servers = [{tag:"dns", type:$type, server:$server, domain_resolver:"local"}, {tag:"local", type:"local"}] | .route.default_domain_resolver = "dns"' \
            --arg type "$is_dns_type" \
            --arg server "$is_dns_use" \
            "$is_config_json" >"$is_config_json.tmp" \
            && mv "$is_config_json.tmp" "$is_config_json"
    else
        jq \
            '.dns.servers = [{address:$addr, address_resolver:"local"}, {tag:"local", address:"local"}]' \
            --arg addr "$is_dns_use" \
            "$is_config_json" >"$is_config_json.tmp" \
            && mv "$is_config_json.tmp" "$is_config_json"
    fi
}

# ── 清除 DNS ──────────────────────────────────────────
dns_clear() {
    jq '.dns = {} | del(.route.default_domain_resolver)' "$is_config_json" >"$is_config_json.tmp" \
        && mv "$is_config_json.tmp" "$is_config_json"
}

# ── 解析 protocol://server ────────────────────────────
dns_set_server() {
    if [[ $(grep '://' <<<$1) ]]; then
        is_tmp_dns_set=($(awk -F '://|/' '{print $1, $2}' <<<${1,,}))
        case ${is_tmp_dns_set[0]} in
        tcp | udp | tls | https | quic | h3)
            is_dns_use=${is_tmp_dns_set[1]}
            is_dns_type=${is_tmp_dns_set[0]}
            ;;
        *)
            err "無法識別 DNS 类型!"
            ;;
        esac
    else
        is_dns_use=$1
        is_dns_type=udp
    fi
}
