#!/bin/bash

protocol_list=(
    TUIC
    Trojan
    Hysteria2
    VMess-WS
    VMess-TCP
    VMess-HTTP
    VMess-QUIC
    Shadowsocks
    VMess-H2-TLS
    VMess-WS-TLS
    VLESS-H2-TLS
    VLESS-WS-TLS
    Trojan-H2-TLS
    Trojan-WS-TLS
    VMess-HTTPUpgrade-TLS
    VLESS-HTTPUpgrade-TLS
    Trojan-HTTPUpgrade-TLS
    VLESS-REALITY
    VLESS-HTTP2-REALITY
    AnyTLS
    # Direct
    Socks
)
ss_method_list=(
    aes-128-gcm
    aes-256-gcm
    chacha20-ietf-poly1305
    xchacha20-ietf-poly1305
    2022-blake3-aes-128-gcm
    2022-blake3-aes-256-gcm
    2022-blake3-chacha20-poly1305
)
mainmenu=(
    "add config"
    "change config"
    "view config"
    "delete config"
    "NextDNS"
    "DNS preset"
    "speed test"
    "health check"
    "backup / restore"
    "traffic stats"
    "start / stop / restart"
    "BBR"
    "log"
    "update"
    "reinstall"
    "uninstall"
    "help"
    "about"
    "language"
)
info_list=(
    "$L_INFO_PROTOCOL (protocol)"
    "$L_INFO_ADDRESS (address)"
    "$L_INFO_PORT (port)"
    "$L_INFO_ID (id)"
    "$L_INFO_NETWORK (network)"
    "$L_INFO_TYPE (type)"
    "$L_INFO_HOST (host)"
    "$L_INFO_PATH (path)"
    "$L_INFO_TLS (TLS)"
    "$L_INFO_ALPN (Alpn)"
    "$L_INFO_PASS (password)"
    "$L_INFO_ENCRYPTION (encryption)"
    "$L_INFO_URL (URL)"
    "$L_INFO_REMOTE_ADDR (remote addr)"
    "$L_INFO_REMOTE_PORT (remote port)"
    "$L_INFO_FLOW (flow)"
    "$L_INFO_SNI (serverName)"
    "$L_INFO_FINGERPRINT (Fingerprint)"
    "$L_INFO_PUBKEY (Public key)"
    "$L_INFO_USER (Username)"
    "$L_INFO_INSECURE (allowInsecure)"
    "$L_INFO_CONGESTION (congestion_control)"
)
change_list=(
    "$L_CHANGE_PROTOCOL"
    "$L_CHANGE_PORT"
    "$L_CHANGE_HOST"
    "$L_CHANGE_PATH"
    "$L_CHANGE_PASS"
    "$L_CHANGE_UUID"
    "$L_CHANGE_METHOD"
    "$L_CHANGE_REMOTE_ADDR"
    "$L_CHANGE_REMOTE_PORT"
    "$L_CHANGE_KEY"
    "$L_CHANGE_SNI"
    "$L_CHANGE_WEB"
    "$L_CHANGE_USER"
)
servername_list=(
    cn.bing.com
    www.amazon.com
    www.ebay.com
    www.paypal.com
    www.cloudflare.com
    dash.cloudflare.com
    aws.amazon.com
)

# shuf fallback for systems without shuf (e.g., Alpine BusyBox)
if ! type -P shuf &>/dev/null; then
    shuf() {
        local min max n
        while [[ $# -gt 0 ]]; do
            case $1 in
            -i) IFS=- read min max <<<"$2"; shift 2 ;;
            -n) n=$2; shift 2 ;;
            esac
        done
        echo $(( RANDOM % (max - min + 1) + min ))
    }
fi

is_random_ss_method=${ss_method_list[$(shuf -i 4-6 -n1)]} # random only use ss2022
is_random_servername=${servername_list[$(shuf -i 0-${#servername_list[@]} -n1) - 1]}

msg() {
    echo -e "$@"
}

msg_ul() {
    echo -e "${c_dim}$@${c_none}"
}

# pause
pause() {
    echo
    echo -ne "按 $(_bright '>>') Enter 繼續, 或按 $(_red '!!') Ctrl-C 取消."
    read -rs -d $'\n'
    echo
}

get_uuid() {
    tmp_uuid=$(cat /proc/sys/kernel/random/uuid)
}

get_ip() {
    [[ $ip || $is_no_auto_tls || $is_gen || $is_dont_get_ip ]] && return
    ip=$(_wget -4 -qO- https://one.one.one.one/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p')
    [[ ! $ip ]] && ip=$(_wget -6 -qO- https://one.one.one.one/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p')
    [[ ! $ip ]] && {
        err "$L_ERR_IP_FAIL"
    }
}

get_port() {
    is_count=0
    while :; do
        ((is_count++))
        if [[ $is_count -ge 233 ]]; then
            err "$L_ERR_PORT_EXHAUSTED"
        fi
        tmp_port=$(shuf -i 445-65535 -n 1)
        [[ ! $(is_test port_used $tmp_port) && $tmp_port != $port ]] && break
    done
}

get_pbk() {
    is_tmp_pbk=($($is_core_bin generate reality-keypair | sed 's/.*://'))
    is_public_key=${is_tmp_pbk[1]}
    is_private_key=${is_tmp_pbk[0]}
}

show_list() {
    local i=0
    for v in "$@"; do
        ((i++))
        echo " [$i] ${v}"
    done
    echo
}

is_test() {
    case $1 in
    number)
        [[ $2 =~ ^[1-9][0-9]*$ ]] && echo ok
        ;;
    port)
        if [[ $(is_test number $2) ]]; then
            [[ $2 -ge 10000 && $2 -le 65535 ]] && echo ok
        fi
        ;;
    port_used)
        [[ $(is_port_used $2) && ! $is_cant_test_port ]] && echo ok
        ;;
    domain)
        [[ $2 =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && echo ok
        ;;
    path)
        [[ $2 =~ ^\/[a-zA-Z0-9_\-\.\/]+$ ]] && echo ok
        ;;
    uuid)
        [[ $2 =~ [0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12} ]] && echo ok
        ;;
    esac

}

is_port_used() {
    if [[ $(type -P netstat) ]]; then
        [[ ! $is_used_port ]] && is_used_port="$(netstat -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)"
        echo $is_used_port | sed 's/ /\n/g' | grep ^${1}$
        return
    fi
    if [[ $(type -P ss) ]]; then
        [[ ! $is_used_port ]] && is_used_port="$(ss -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)"
        echo $is_used_port | sed 's/ /\n/g' | grep ^${1}$
        return
    fi
    is_cant_test_port=1
    msg "$is_warn $L_ERR_PORT_DETECT_FAIL"
    msg "$L_ERR_PORT_DETECT_FIX $(_dim $cmd update -y install net-tools)"
}

# ask input a string or pick a option for list.
ask() {
    case $1 in
    set_ss_method)
        is_tmp_list=(${ss_method_list[@]})
        is_default_arg=$is_random_ss_method
        is_opt_msg="\n請選擇加密方式:\n"
        is_opt_input_msg="(默認 $(_bright $is_default_arg)):"
        is_ask_set=ss_method
        ;;
    set_protocol)
        is_tmp_list=(${protocol_list[@]})
        [[ $is_no_auto_tls ]] && {
            unset is_tmp_list
            for v in ${protocol_list[@]}; do
                [[ $(grep -i "\-tls$" <<<$v) ]] && is_tmp_list=(${is_tmp_list[@]} $v)
            done
        }
        is_opt_msg="\n請選擇協議:\n"
        is_ask_set=is_new_protocol
        ;;
    set_change_list)
        is_tmp_list=()
        for v in ${is_can_change[@]}; do
            is_tmp_list+=("${change_list[$v]}")
        done
        is_opt_msg="\n請選擇更改:\n"
        is_ask_set=is_change_str
        is_opt_input_msg=$3
        ;;
    string)
        is_ask_set=$2
        is_opt_input_msg=$3
        ;;
    list)
        is_ask_set=$2
        [[ ! $is_tmp_list ]] && is_tmp_list=($3)
        is_opt_msg=$4
        is_opt_input_msg=$5
        ;;
    get_config_file)
        is_tmp_list=("${is_all_json[@]}")
        is_opt_msg="\n請選擇配置:\n"
        is_ask_set=is_config_file
        ;;
    mainmenu)
        is_tmp_list=("${mainmenu[@]}")
        is_ask_set=is_main_pick
        is_emtpy_exit=1
        ;;
    esac
    msg $is_opt_msg
    [[ ! $is_opt_input_msg ]] && is_opt_input_msg="請選擇 $(_bright 1-${#is_tmp_list[@]}):"
    [[ $is_tmp_list ]] && show_list "${is_tmp_list[@]}"
    while :; do
        echo -ne $is_opt_input_msg
        read REPLY
        [[ ! $REPLY && $is_emtpy_exit ]] && exit
        [[ ! $REPLY && $is_default_arg ]] && export $is_ask_set=$is_default_arg && break
        [[ "$REPLY" == "${is_str}2${is_get}3${is_opt}3" && $is_ask_set == 'is_main_pick' ]] && {
            msg "\n${is_get}2${is_str}3${is_msg}3b${is_tmp}o${is_opt}y\n" && exit
        }
        if [[ ! $is_tmp_list ]]; then
            [[ $(grep port <<<$is_ask_set) ]] && {
                [[ ! $(is_test port "$REPLY") ]] && {
                    msg "$is_err 請輸入正確的端口, 可選(10000-65535)"
                    continue
                }
                if [[ $(is_test port_used $REPLY) && $is_ask_set != 'door_port' ]]; then
                    msg "$is_err 無法使用 ($REPLY) 端口."
                    continue
                fi
            }
            [[ $(grep path <<<$is_ask_set) && ! $(is_test path "$REPLY") ]] && {
                [[ ! $tmp_uuid ]] && get_uuid
                msg "$is_err 請輸入正確的路徑, 例如: /$tmp_uuid"
                continue
            }
            [[ $(grep uuid <<<$is_ask_set) && ! $(is_test uuid "$REPLY") ]] && {
                [[ ! $tmp_uuid ]] && get_uuid
                msg "$is_err 請輸入正確的 UUID, 例如: $tmp_uuid"
                continue
            }
            [[ $(grep ^y$ <<<$is_ask_set) ]] && {
                [[ $(grep -i ^y$ <<<"$REPLY") ]] && break
                msg "請輸入 (y)"
                continue
            }
            [[ $REPLY ]] && export $is_ask_set=$REPLY && msg "使用: ${!is_ask_set}" && break
        else
            [[ $(is_test number "$REPLY") ]] && is_ask_result=${is_tmp_list[$REPLY - 1]}
            [[ $is_ask_result ]] && export $is_ask_set="$is_ask_result" && msg "選擇: ${!is_ask_set}" && break
        fi

        msg "輸入${is_err}"
    done
    unset is_opt_msg is_opt_input_msg is_tmp_list is_ask_result is_default_arg is_emtpy_exit
}

# create file
create() {
    case $1 in
    server)
        is_tls=none
        get new
        # listen
        is_listen='listen: "::"'
        # file name - 隨機5位數字
        is_config_name=$(shuf -i 10000-99999 -n 1).json
        [[ $host ]] && is_listen='listen: "127.0.0.1"'
        is_json_file=$is_conf_dir/$is_config_name
        # get json
        [[ $is_change || ! $json_str ]] && get protocol $2
        [[ $net == "reality" ]] && is_add_public_key=",outbounds:[{type:\"direct\"},{tag:\"public_key_$is_public_key\",type:\"direct\"}]"
        is_new_json=$(jq "{inbounds:[{tag:\"$is_config_name\",type:\"$is_protocol\",$is_listen,listen_port:$port,$json_str}]$is_add_public_key}" <<<{})
        [[ $is_test_json ]] && return # tmp test
        # only show json, dont save to file.
        [[ $is_gen ]] && {
            msg
            jq <<<$is_new_json
            msg
            return
        }
        # del old file
        [[ $is_config_file ]] && is_no_del_msg=1 && del $is_config_file
        # save json to file
        cat <<<$is_new_json >$is_json_file
        if [[ $is_new_install ]]; then
            # config.json
            create config.json
        fi
        # caddy auto tls
        [[ $is_caddy && $host && ! $is_no_auto_tls ]] && {
            create caddy $net
        }
        # restart core
        manage restart &
        ;;
    client)
        is_tls=tls
        is_client=1
        get info $2
        [[ ! $is_client_id_json ]] && err "($is_config_name) 不支援生成客戶端配置。"
        is_new_json=$(jq '{outbounds:[{tag:'\"$is_config_name\"',protocol:'\"$is_protocol\"','"$is_client_id_json"','"$is_stream"'}]}' <<<{})
        msg
        jq <<<$is_new_json
        msg
        ;;
    caddy)
        load caddy.sh
        [[ $is_install_caddy ]] && caddy_config new
        [[ ! $(grep "$is_caddy_conf" $is_caddyfile) ]] && {
            msg "import $is_caddy_conf/*.conf" >>$is_caddyfile
        }
        [[ ! -d $is_caddy_conf ]] && mkdir -p $is_caddy_conf
        caddy_config $2
        manage restart caddy &
        ;;
    config.json)
        is_ntp='ntp:{"enabled":true,"server":"time.apple.com"},'
        if [[ -f $is_config_json ]]; then
            [[ $(jq .ntp.enabled $is_config_json) != "true" ]] && is_ntp=
        else
            [[ ! $is_ntp_on ]] && is_ntp=
        fi
        jq -n \
            --arg log_dir "$is_log_dir" \
            '{log:{output:($log_dir + "/access.log"), level:"info", timestamp:true}, dns:{}, '"$is_ntp"' outbounds:[{tag:"direct", type:"direct"}]}' \
            >"$is_config_json.tmp" && mv "$is_config_json.tmp" "$is_config_json"
        manage restart &
        ;;
    esac
}

# change config file
change() {
    is_change=1
    is_dont_show_info=1
    if [[ $2 ]]; then
        case ${2,,} in
        full)
            is_change_id=full
            ;;
        new)
            is_change_id=0
            ;;
        port)
            is_change_id=1
            ;;
        host)
            is_change_id=2
            ;;
        path)
            is_change_id=3
            ;;
        pass | passwd | password)
            is_change_id=4
            ;;
        id | uuid)
            is_change_id=5
            ;;
        ssm | method | ss-method | ss_method)
            is_change_id=6
            ;;
        dda | door-addr | door_addr)
            is_change_id=7
            ;;
        ddp | door-port | door_port)
            is_change_id=8
            ;;
        key | publickey | privatekey)
            is_change_id=9
            ;;
        sni | servername | servernames)
            is_change_id=10
            ;;
        web | proxy-site)
            is_change_id=11
            ;;
        *)
            [[ $is_try_change ]] && return
            err "無法識別 ($2) 更改类型."
            ;;
        esac
    fi
    [[ $is_try_change ]] && return
    [[ $is_dont_auto_exit ]] && {
        get info $1
    } || {
        [[ $is_change_id ]] && {
            is_change_msg=${change_list[$is_change_id]}
            [[ $is_change_id == 'full' ]] && {
                [[ $3 ]] && is_change_msg="更改多個參數" || is_change_msg=
            }
            [[ $is_change_msg ]] && _bright "\n>> $is_change_msg"
        }
        info $1
        [[ $is_auto_get_config ]] && msg "\n自動選擇: $is_config_file"
    }
    is_old_net=$net
    [[ $is_tcp_http ]] && net=http
    [[ $host ]] && net=$is_protocol-$net-tls
    [[ $is_reality && $net_type =~ 'http' ]] && net=rh2

    [[ $3 == 'auto' ]] && is_auto=1
    # if is_dont_show_info exist, cant show info.
    is_dont_show_info=
    # if not prefer args, show change list and then get change id.
    [[ ! $is_change_id ]] && {
        ask set_change_list
        is_change_id=${is_can_change[$REPLY - 1]}
    }
    case $is_change_id in
    full)
        add $net ${@:3}
        ;;
    0)
        # new protocol
        is_set_new_protocol=1
        add ${@:3}
        ;;
    1)
        # new port
        is_new_port=$3
        [[ $host && ! $is_caddy || $is_no_auto_tls ]] && err "($is_config_file) 不支援更改端口, 因為沒啥意義."
        if [[ $is_new_port && ! $is_auto ]]; then
            [[ ! $(is_test port $is_new_port) ]] && err "請輸入正確的端口, 可選(10000-65535)"
            [[ $is_new_port != 443 && $(is_test port_used $is_new_port) ]] && err "無法使用 ($is_new_port) 端口"
        fi
        [[ $is_auto ]] && get_port && is_new_port=$tmp_port
        [[ ! $is_new_port ]] && ask string is_new_port "請輸入新端口:"
        if [[ $is_caddy && $host ]]; then
            net=$is_old_net
            is_https_port=$is_new_port
            load caddy.sh
            caddy_config $net
            manage restart caddy &
            info
        else
            add $net $is_new_port
        fi
        ;;
    2)
        # new host
        is_new_host=$3
        [[ ! $host ]] && err "($is_config_file) 不支援更改域名."
        [[ ! $is_new_host ]] && ask string is_new_host "請輸入新域名:"
        old_host=$host # del old host
        add $net $is_new_host
        ;;
    3)
        # new path
        is_new_path=$3
        [[ ! $path ]] && err "($is_config_file) 不支援更改路徑."
        [[ $is_auto ]] && get_uuid && is_new_path=/$tmp_uuid
        [[ ! $is_new_path ]] && ask string is_new_path "請輸入新路徑:"
        add $net auto auto $is_new_path
        ;;
    4)
        # new password
        is_new_pass=$3
        if [[ $ss_password || $password ]]; then
            [[ $is_auto ]] && {
                get_uuid && is_new_pass=$tmp_uuid
                [[ $ss_password ]] && is_new_pass=$(get ss2022)
            }
        else
            err "($is_config_file) 不支援更改密碼."
        fi
        [[ ! $is_new_pass ]] && ask string is_new_pass "請輸入新密碼:"
        password=$is_new_pass
        ss_password=$is_new_pass
        is_socks_pass=$is_new_pass
        add $net
        ;;
    5)
        # new uuid
        is_new_uuid=$3
        [[ ! $uuid ]] && err "($is_config_file) 不支援更改 UUID."
        [[ $is_auto ]] && get_uuid && is_new_uuid=$tmp_uuid
        [[ ! $is_new_uuid ]] && ask string is_new_uuid "請輸入新 UUID:"
        add $net auto $is_new_uuid
        ;;
    6)
        # new method
        is_new_method=$3
        [[ $net != 'ss' ]] && err "($is_config_file) 不支援更改加密方式."
        [[ $is_auto ]] && is_new_method=$is_random_ss_method
        [[ ! $is_new_method ]] && {
            ask set_ss_method
            is_new_method=$ss_method
        }
        add $net auto auto $is_new_method
        ;;
    7)
        # new remote addr
        is_new_door_addr=$3
        [[ $net != 'direct' ]] && err "($is_config_file) 不支援更改目标地址."
        [[ ! $is_new_door_addr ]] && ask string is_new_door_addr "請輸入新的目标地址:"
        door_addr=$is_new_door_addr
        add $net
        ;;
    8)
        # new remote port
        is_new_door_port=$3
        [[ $net != 'direct' ]] && err "($is_config_file) 不支援更改目标端口."
        [[ ! $is_new_door_port ]] && {
            ask string door_port "請輸入新的目标端口:"
            is_new_door_port=$door_port
        }
        add $net auto auto $is_new_door_port
        ;;
    9)
        # new is_private_key is_public_key
        is_new_private_key=$3
        is_new_public_key=$4
        [[ ! $is_reality ]] && err "($is_config_file) 不支援更改密钥."
        if [[ $is_auto ]]; then
            get_pbk
            add $net
        else
            [[ $is_new_private_key && ! $is_new_public_key ]] && {
                err "無法找到 Public key."
            }
            [[ ! $is_new_private_key ]] && ask string is_new_private_key "請輸入新 Private key:"
            [[ ! $is_new_public_key ]] && ask string is_new_public_key "請輸入新 Public key:"
            if [[ $is_new_private_key == $is_new_public_key ]]; then
                err "Private key 和 Public key 不能一样."
            fi
            is_tmp_json=$is_conf_dir/$is_config_file-$uuid
            cp -f $is_conf_dir/$is_config_file $is_tmp_json
            sed -i s#$is_private_key #$is_new_private_key# $is_tmp_json
            $is_core_bin check -c $is_tmp_json &>/dev/null
            if [[ $? != 0 ]]; then
                is_key_err=1
                is_key_err_msg="Private key 無法通過測試."
            fi
            sed -i s#$is_new_private_key #$is_new_public_key# $is_tmp_json
            $is_core_bin check -c $is_tmp_json &>/dev/null
            if [[ $? != 0 ]]; then
                is_key_err=1
                is_key_err_msg+="Public key 無法通過測試."
            fi
            rm $is_tmp_json
            [[ $is_key_err ]] && err $is_key_err_msg
            is_private_key=$is_new_private_key
            is_public_key=$is_new_public_key
            is_test_json=
            add $net
        fi
        ;;
    10)
        # new serverName
        is_new_servername=$3
        [[ ! $is_reality ]] && err "($is_config_file) 不支援更改 serverName."
        [[ $is_auto ]] && is_new_servername=$is_random_servername
        [[ ! $is_new_servername ]] && ask string is_new_servername "請輸入新的 serverName:"
        is_servername=$is_new_servername
        [[ $(grep -i "^cn.bing.com$" <<<$is_servername) ]] && {
            err "domain blocked"
        }
        add $net
        ;;
    11)
        # new proxy site
        is_new_proxy_site=$3
        [[ ! $is_caddy && ! $host ]] && {
            err "($is_config_file) 不支援更改偽裝網站."
        }
        [[ ! -f $is_caddy_conf/${host}.conf.add ]] && err "無法配置偽裝網站."
        [[ ! $is_new_proxy_site ]] && ask string is_new_proxy_site "請輸入新的偽裝網站 (例如 example.com):"
        proxy_site=$(sed 's#^.*//##;s#/$##' <<<$is_new_proxy_site)
        [[ $(grep -i "^cn.bing.com$" <<<$proxy_site) ]] && {
            err "domain blocked"
        } || {
            load caddy.sh
            caddy_config proxy
            manage restart caddy &
        }
        msg "\n  $(_bright $proxy_site)\n"
        ;;
    12)
        # new socks user
        [[ ! $is_socks_user ]] && err "($is_config_file) 不支援更改用戶名 (Username)."
        ask string is_socks_user "請輸入新用戶名 (Username):"
        add $net
        ;;
    esac
}

# delete config.
del() {
    # dont get ip
    is_dont_get_ip=1
    [[ $is_conf_dir_empty ]] && return # not found any json file.
    # get a config file
    [[ ! $is_config_file ]] && get info $1
    if [[ $is_config_file ]]; then
        if [[ $is_main_start && ! $is_no_del_msg ]]; then
            msg "\n是否刪除配置檔案？: $is_config_file"
            pause
        fi
        rm -rf $is_conf_dir/"$is_config_file"
        [[ ! $is_new_json ]] && manage restart &
        [[ ! $is_no_del_msg ]] && _bright "\n  $is_config_file deleted\n"

        [[ $is_caddy ]] && {
            is_del_host=$host
            [[ $is_change ]] && {
                [[ ! $old_host ]] && return # no host exist or not set new host;
                is_del_host=$old_host
            }
            [[ $is_del_host && $host != $old_host && -f $is_caddy_conf/$is_del_host.conf ]] && {
                rm -rf $is_caddy_conf/$is_del_host.conf $is_caddy_conf/$is_del_host.conf.add
                [[ ! $is_new_json ]] && manage restart caddy &
            }
        }
    fi
    if [[ ! $(ls $is_conf_dir | grep .json) && ! $is_change ]]; then
        warn "當前配置目錄為空！因為你剛剛刪除了最後一個配置檔案。"
        is_conf_dir_empty=1
    fi
    unset is_dont_get_ip
    [[ $is_dont_auto_exit ]] && unset is_config_file
}

# uninstall
uninstall() {
    if [[ $is_caddy ]]; then
        is_tmp_list=("卸載 $is_core_name" "卸載 ${is_core_name} & Caddy")
        ask list is_do_uninstall
    else
        ask string y "是否卸載 ${is_core_name}？[y]:"
    fi
    manage stop &>/dev/null
    manage disable &>/dev/null
    rm -rf $is_core_dir $is_log_dir $is_sh_bin ${is_sh_bin/$is_sh_name/sb}
    if [[ $is_systemd ]]; then
        rm -f /lib/systemd/system/$is_core.service
    elif [[ $is_openrc ]]; then
        rm -f /etc/init.d/$is_core
    fi
    sed -i "/$is_sh_name/d" /root/.bashrc
    # uninstall caddy; 2 is ask result
    if [[ $REPLY == '2' ]]; then
        manage stop caddy &>/dev/null
        manage disable caddy &>/dev/null
        if [[ $is_systemd ]]; then
            rm -rf $is_caddy_dir $is_caddy_bin /lib/systemd/system/caddy.service
        elif [[ $is_openrc ]]; then
            rm -rf $is_caddy_dir $is_caddy_bin /etc/init.d/caddy
        fi
    fi
    [[ $is_install_sh ]] && return # reinstall
    _bright "\n>> uninstall done"
    msg "腳本哪里需要完善? 請反饋"
    msg "反饋問題) $(msg_ul https://github.com/${is_sh_repo}/issues)\n"
}

# manage run status
manage() {
    [[ $is_dont_auto_exit ]] && return
    case $1 in
    1 | start)
        is_do=start
        is_do_msg=啟動
        is_test_run=1
        ;;
    2 | stop)
        is_do=stop
        is_do_msg=停止
        ;;
    3 | r | restart)
        is_do=restart
        is_do_msg=重啟
        is_test_run=1
        ;;
    *)
        is_do=$1
        is_do_msg=$1
        ;;
    esac
    case $2 in
    caddy)
        is_do_name=$2
        is_run_bin=$is_caddy_bin
        is_do_name_msg=Caddy
        ;;
    *)
        is_do_name=$is_core
        is_run_bin=$is_core_bin
        is_do_name_msg=$is_core_name
        ;;
    esac
    if [[ $is_systemd ]]; then
        systemctl $is_do $is_do_name 2>/dev/null
    elif [[ $is_openrc ]]; then
        case $is_do in
        enable)
            rc-update add $is_do_name default 2>/dev/null
            ;;
        disable)
            rc-update del $is_do_name default 2>/dev/null
            ;;
        *)
            rc-service $is_do_name $is_do 2>/dev/null
            ;;
        esac
    fi
    [[ $is_test_run && ! $is_new_install ]] && {
        sleep 2
        if [[ ! $(pgrep -f $is_run_bin) ]]; then
            is_run_fail=${is_do_name_msg,,}
            [[ ! $is_no_manage_msg ]] && {
                msg
                warn "($is_do_msg) $is_do_name_msg 失敗"
                _dim ">> run failed, 自動執行测試運行."
                get test-run
                _dim ">> test done, press Enter to exit."
            }
        fi
    }
}

# add a config
add() {
    is_lower=${1,,}
    if [[ $is_lower ]]; then
        case $is_lower in
        ws | tcp | quic | http)
            is_new_protocol=VMess-${is_lower^^}
            ;;
        wss | h2 | hu | vws | vh2 | vhu | tws | th2 | thu)
            is_new_protocol=$(sed -E "s/^V/VLESS-/;s/^T/Trojan-/;/^(W|H)/{s/^/VMess-/};s/WSS/WS/;s/HU/HTTPUpgrade/" <<<${is_lower^^})-TLS
            ;;
        r | reality)
            is_new_protocol=VLESS-REALITY
            ;;
        rh2)
            is_new_protocol=VLESS-HTTP2-REALITY
            ;;
        ss)
            is_new_protocol=Shadowsocks
            ;;
        door | direct)
            is_new_protocol=Direct
            ;;
        tuic)
            is_new_protocol=TUIC
            ;;
        hy | hy2 | hysteria*)
            is_new_protocol=Hysteria2
            ;;
        trojan)
            is_new_protocol=Trojan
            ;;
        anytls)
            is_new_protocol=AnyTLS
            ;;
        socks)
            is_new_protocol=Socks
            ;;
        *)
            for v in ${protocol_list[@]}; do
                [[ $(grep -E -i "^$is_lower$" <<<$v) ]] && is_new_protocol=$v && break
            done

            [[ ! $is_new_protocol ]] && err "$L_ERR_UNKNOWN_PROTOCOL $is_sh_name add [protocol] [args... | auto]"
            ;;
        esac
    fi

    # no prefer protocol
    [[ ! $is_new_protocol ]] && ask set_protocol

    if [[ ${is_new_protocol,,} == 'anytls' ]]; then
        is_core_major=${is_core_ver%%.*}
        is_core_minor=$(echo "$is_core_ver" | cut -d. -f2)
        if [[ ${is_core_major:-0} -lt 1 || ( ${is_core_major:-0} -eq 1 && ${is_core_minor:-0} -lt 12 ) ]]; then
            err "$L_ERR_ANYTLS_VERSION ($is_core_ver)"
        fi
    fi

    case ${is_new_protocol,,} in
    *-tls)
        is_use_tls=1
        is_use_host=$2
        is_use_uuid=$3
        is_use_path=$4
        is_add_opts="[host] [uuid] [/path]"
        ;;
    vmess* | tuic*)
        is_use_port=$2
        is_use_uuid=$3
        is_add_opts="[port] [uuid]"
        ;;
    trojan* | hysteria*)
        is_use_port=$2
        is_use_pass=$3
        is_add_opts="[port] [password]"
        ;;
    *reality*)
        is_reality=1
        is_use_port=$2
        is_use_uuid=$3
        is_use_servername=$4
        is_add_opts="[port] [uuid] [sni]"
        ;;
    shadowsocks)
        is_use_port=$2
        is_use_pass=$3
        is_use_method=$4
        is_add_opts="[port] [password] [method]"
        ;;
    direct)
        is_use_port=$2
        is_use_door_addr=$3
        is_use_door_port=$4
        is_add_opts="[port] [remote_addr] [remote_port]"
        ;;
    anytls*)
        is_use_port=$2
        is_use_pass=$3
        [[ $4 ]] && is_anytls_domain=$4
        is_add_opts="[port] [password] [domain]"
        ;;
    socks)
        is_socks=1
        is_use_port=$2
        is_use_socks_user=$3
        is_use_socks_pass=$4
        is_add_opts="[port] [username] [password]"
        ;;
    esac

    [[ $1 && ! $is_change ]] && {
        msg "\n使用協議: $is_new_protocol"
        # err msg tips
        is_err_tips="\\n\\n請使用: $(_bright "$is_sh_name add $1 $is_add_opts") 來添加 $is_new_protocol 配置"
    }

    # remove old protocol args
    if [[ $is_set_new_protocol ]]; then
        case $is_old_net in
        h2 | ws | httpupgrade)
            old_host=$host
            [[ ! $is_use_tls ]] && unset host is_no_auto_tls
            ;;
        reality)
            net_type=
            [[ ! $(grep -i reality <<<$is_new_protocol) ]] && is_reality=
            ;;
        ss)
            [[ $(is_test uuid $ss_password) ]] && uuid=$ss_password
            ;;
        esac
        [[ ! $(is_test uuid $uuid) ]] && uuid=
        [[ $(is_test uuid $password) ]] && uuid=$password
    fi

    # no-auto-tls only use h2,ws,grpc
    if [[ $is_no_auto_tls && ! $is_use_tls ]]; then
        err "$is_new_protocol 不支援手動配置 tls."
    fi

    # prefer args.
    if [[ $2 ]]; then
        for v in is_use_port is_use_uuid is_use_host is_use_path is_use_pass is_use_method is_use_door_addr is_use_door_port; do
            [[ ${!v} == 'auto' ]] && unset $v
        done

        if [[ $is_use_port ]]; then
            [[ ! $(is_test port ${is_use_port}) ]] && {
                err "($is_use_port) 不是一個有效的端口. $is_err_tips"
            }
            [[ $(is_test port_used $is_use_port) && ! $is_gen ]] && {
                err "無法使用 ($is_use_port) 端口. $is_err_tips"
            }
            port=$is_use_port
        fi
        if [[ $is_use_door_port ]]; then
            [[ ! $(is_test port ${is_use_door_port}) ]] && {
                err "(${is_use_door_port}) 不是一個有效的目标端口. $is_err_tips"
            }
            door_port=$is_use_door_port
        fi
        if [[ $is_use_uuid ]]; then
            [[ ! $(is_test uuid $is_use_uuid) ]] && {
                err "($is_use_uuid) 不是一個有效的 UUID. $is_err_tips"
            }
            uuid=$is_use_uuid
        fi
        if [[ $is_use_path ]]; then
            [[ ! $(is_test path $is_use_path) ]] && {
                err "($is_use_path) 不是有效的路徑. $is_err_tips"
            }
            path=$is_use_path
        fi
        if [[ $is_use_method ]]; then
            is_tmp_use_name=加密方式
            is_tmp_list=${ss_method_list[@]}
            for v in ${is_tmp_list[@]}; do
                [[ $(grep -E -i "^${is_use_method}$" <<<$v) ]] && is_tmp_use_type=$v && break
            done
            [[ ! ${is_tmp_use_type} ]] && {
                warn "(${is_use_method}) 不是一個可用的${is_tmp_use_name}."
                msg "${is_tmp_use_name}可用如下: "
                for v in ${is_tmp_list[@]}; do
                    msg "\t\t$v"
                done
                msg "$is_err_tips\n"
                exit 1
            }
            ss_method=$is_tmp_use_type
        fi
        [[ $is_use_pass ]] && ss_password=$is_use_pass && password=$is_use_pass
        [[ $is_use_host ]] && host=$is_use_host
        [[ $is_use_door_addr ]] && door_addr=$is_use_door_addr
        [[ $is_use_servername ]] && is_servername=$is_use_servername
        [[ $is_use_socks_user ]] && is_socks_user=$is_use_socks_user
        [[ $is_use_socks_pass ]] && is_socks_pass=$is_use_socks_pass
    fi

    # anytls with domain (ACME TLS)
    if [[ $is_anytls_domain && ! $is_change && ! $is_gen ]]; then
        get_ip
        host=$is_anytls_domain
        get host-test
        host=
    fi

    if [[ $is_use_tls ]]; then
        if [[ ! $is_no_auto_tls && ! $is_caddy && ! $is_gen && ! $is_dont_test_host ]]; then
            # test auto tls
            [[ $(is_test port_used 80) || $(is_test port_used 443) ]] && {
                get_port
                is_http_port=$tmp_port
                get_port
                is_https_port=$tmp_port
                warn "端口 (80 或 443) 已经被占用, 你也可以考虑使用 no-auto-tls"
                msg "幫助(help): $(msg_ul https://doc.wahsun.org/$is_core/no-auto-tls/)\n"
                msg "\n Caddy 將使用非標準端口實現自動配置 TLS, HTTP:$is_http_port HTTPS:$is_https_port\n"
                msg "請確定是否繼續???"
                pause
            }
            is_install_caddy=1
        fi
        # set host
        [[ ! $host ]] && ask string host "請輸入域名:"
        # test host dns
        get host-test
    else
        # for main menu start, dont auto create args
        if [[ $is_main_start ]]; then

            # set port
            [[ ! $port ]] && ask string port "請輸入端口:"

            case ${is_new_protocol,,} in
            socks)
                # set user
                [[ ! $is_socks_user ]] && ask string is_socks_user "請設置用戶名:"
                # set password
                [[ ! $is_socks_pass ]] && ask string is_socks_pass "請設置密碼:"
                ;;
            shadowsocks)
                # set method
                [[ ! $ss_method ]] && ask set_ss_method
                # set password
                [[ ! $ss_password ]] && ask string ss_password "請設置密碼:"
                ;;
            esac

        fi
    fi

    # Dokodemo-Door
    if [[ $is_new_protocol == 'Direct' ]]; then
        # set remote addr
        [[ ! $door_addr ]] && ask string door_addr "請輸入目标地址:"
        # set remote port
        [[ ! $door_port ]] && ask string door_port "請輸入目标端口:"
    fi

    # Shadowsocks 2022
    if [[ $(grep 2022 <<<$ss_method) ]]; then
        # test ss2022 password
        [[ $ss_password ]] && {
            is_test_json=1
            create server Shadowsocks
            [[ ! $tmp_uuid ]] && get_uuid
            is_test_json_save=$is_conf_dir/tmp-test-$tmp_uuid
            cat <<<"$is_new_json" >$is_test_json_save
            $is_core_bin check -c $is_test_json_save &>/dev/null
            if [[ $? != 0 ]]; then
                warn "Shadowsocks 協議 ($ss_method) 不支援使用密碼 ($(_red $ss_password))\n\n你可以使用命令: $(_bright "$is_sh_name ss2022") 生成支援的密碼.\n\n腳本將自動創建可用密碼:)"
                ss_password=
                # create new json.
                json_str=
            fi
            is_test_json=
            rm -f $is_test_json_save
        }

    fi

    # install caddy
    if [[ $is_install_caddy ]]; then
        get install-caddy
    fi

    # create json
    create server $is_new_protocol

    # show config info.
    info
}

# get config info
# or somes required args
get() {
    case $1 in
    addr)
        is_addr=$host
        [[ ! $is_addr ]] && {
            get_ip
            is_addr=$ip
            [[ $(grep ":" <<<$ip) ]] && is_addr="[$ip]"
        }
        ;;
    new)
        [[ ! $host ]] && get_ip
        [[ ! $port ]] && get_port && port=$tmp_port
        [[ ! $uuid ]] && get_uuid && uuid=$tmp_uuid
        ;;
    file)
        is_file_str=$2
        [[ ! $is_file_str ]] && is_file_str='.json$'
        # is_all_json=("$(ls $is_conf_dir | grep -E $is_file_str)")
        readarray -t is_all_json <<<"$(ls $is_conf_dir | grep -E -i "$is_file_str" | sed '/dynamic-port-.*-link/d' | head -233)" # limit max 233 lines for show.
        [[ ! $is_all_json ]] && err "無法找到相關的配置檔案: $2"
        [[ ${#is_all_json[@]} -eq 1 ]] && is_config_file=$is_all_json && is_auto_get_config=1
        [[ ! $is_config_file ]] && {
            [[ $is_dont_auto_exit ]] && return
            ask get_config_file
        }
        ;;
    info)
        get file $2
        if [[ $is_config_file ]]; then
            is_json_str=$(cat $is_conf_dir/"$is_config_file" | sed s#//.*##)
            is_json_data=$(jq '(.inbounds[0]|.type,.listen_port,(.users[0]|.uuid,.password,.username),.method,.password,.override_port,.override_address,(.transport|.type,.path,.headers.host),(.tls|.server_name,.reality.private_key)),(.outbounds[1].tag)' <<<$is_json_str)
            [[ $? != 0 ]] && err "無法读取此檔案: $is_config_file"
            is_up_var_set=(null is_protocol port uuid password username ss_method ss_password door_port door_addr net_type path host is_servername is_private_key is_public_key)
            [[ $is_debug ]] && msg "\n------------- debug: $is_config_file -------------"
            i=0
            for v in $(sed 's/""/null/g;s/"//g' <<<"$is_json_data"); do
                ((i++))
                [[ $is_debug ]] && msg "$i-${is_up_var_set[$i]}: $v"
                export ${is_up_var_set[$i]}="${v}"
            done
            for v in ${is_up_var_set[@]}; do
                [[ ${!v} == 'null' ]] && unset $v
            done

            if [[ $is_private_key ]]; then
                is_reality=1
                net_type+=reality
                is_public_key=${is_public_key/public_key_/}
            fi
            is_socks_user=$username
            is_socks_pass=$password

            # extract anytls ACME domain
            [[ $is_protocol == 'anytls' ]] && {
                is_anytls_domain=$(jq -r '(.inbounds[0].tls.certificate_provider.domain[0] // .inbounds[0].tls.acme.domain[0]) // empty' <<<$is_json_str 2>/dev/null)
            }

            is_config_name=$is_config_file

            if [[ $is_caddy && $host && -f $is_caddy_conf/$host.conf ]]; then
                is_tmp_https_port=$(grep -E -o "$host:[1-9][0-9]?+" $is_caddy_conf/$host.conf | sed s/.*://)
            fi
            if [[ $host && ! -f $is_caddy_conf/$host.conf ]]; then
                is_no_auto_tls=1
            fi
            [[ $is_tmp_https_port ]] && is_https_port=$is_tmp_https_port
            [[ $is_client && $host ]] && port=$is_https_port
            get protocol $is_protocol-$net_type
        fi
        ;;
    protocol)
        get addr # get host or server ip
        is_lower=${2,,}
        net=
        is_users="users:[{uuid:\"$uuid\"}]"
        is_tls_json='tls:{enabled:true,alpn:["h3"],key_path:"'$is_tls_key'",certificate_path:"'$is_tls_cer'"}'
        case $is_lower in
        vmess*)
            is_protocol=vmess
            [[ $is_lower =~ "tcp" || ! $net_type && $is_up_var_set ]] && net=tcp && json_str=$is_users
            ;;
        vless*)
            is_protocol=vless
            ;;
        tuic*)
            net=tuic
            is_protocol=$net
            [[ ! $password ]] && password=$uuid
            is_users="users:[{uuid:\"$uuid\",password:\"$password\"}]"
            json_str="$is_users,congestion_control:\"bbr\",$is_tls_json"
            ;;
        trojan*)
            is_protocol=trojan
            [[ ! $password ]] && password=$uuid
            is_users="users:[{password:\"$password\"}]"
            [[ ! $host ]] && {
                net=trojan
                json_str="$is_users,${is_tls_json/alpn\:\[\"h3\"\],/}"
            }
            ;;
        hysteria2*)
            net=hysteria2
            is_protocol=$net
            [[ ! $password ]] && password=$uuid
            json_str="users:[{password:\"$password\"}],$is_tls_json"
            ;;
        shadowsocks*)
            net=ss
            is_protocol=shadowsocks
            [[ ! $ss_method ]] && ss_method=$is_random_ss_method
            [[ ! $ss_password ]] && {
                ss_password=$uuid
                [[ $(grep 2022 <<<$ss_method) ]] && ss_password=$(get ss2022)
            }
            json_str="method:\"$ss_method\",password:\"$ss_password\""
            ;;
        direct*)
            net=direct
            is_protocol=$net
            json_str="override_port:$door_port,override_address:\"$door_addr\""
            ;;
        anytls*)
            net=anytls
            is_protocol=$net
            [[ ! $password ]] && password=$uuid
            is_users="users:[{password:\"$password\"}]"
            if [[ $is_anytls_domain ]]; then
                # sing-box >= 1.14.0 uses certificate_provider; older uses acme
                is_core_minor=$(echo "$is_core_ver" | cut -d. -f2)
                if [[ ${is_core_minor:-0} -ge 14 ]]; then
                    is_anytls_tls="tls:{enabled:true,certificate_provider:{type:\"acme\",domain:[\"$is_anytls_domain\"]}}"
                else
                    is_anytls_tls="tls:{enabled:true,acme:{domain:[\"$is_anytls_domain\"]}}"
                fi
            else
                is_anytls_tls="${is_tls_json/alpn\:\[\"h3\"\],/}"
            fi
            json_str="$is_users,$is_anytls_tls"
            ;;
        socks*)
            net=socks
            is_protocol=$net
            [[ ! $is_socks_user ]] && is_socks_user=WAHSUN
            [[ ! $is_socks_pass ]] && is_socks_pass=$uuid
            json_str="users:[{username: \"$is_socks_user\", password: \"$is_socks_pass\"}]"
            ;;
        *)
            err "無法識別協議: $is_config_file"
            ;;
        esac
        [[ $net ]] && return # if net exist, dont need more json args
        [[ $host && $is_lower =~ "tls" ]] && {
            [[ ! $path ]] && path="/$uuid"
            is_path_host_json=",path:\"$path\",headers:{host:\"$host\"}"
        }
        case $is_lower in
        *quic*)
            net=quic
            is_json_add="$is_tls_json,transport:{type:\"$net\"}"
            ;;
        *ws*)
            net=ws
            is_json_add="transport:{type:\"$net\"$is_path_host_json,early_data_header_name:\"Sec-WebSocket-Protocol\"}"
            ;;
        *reality*)
            net=reality
            [[ ! $is_servername ]] && is_servername=$is_random_servername
            [[ ! $is_private_key ]] && get_pbk
            is_json_add="tls:{enabled:true,server_name:\"$is_servername\",reality:{enabled:true,handshake:{server:\"$is_servername\",server_port:443},private_key:\"$is_private_key\",short_id:[\"\"]}}"
            [[ $is_lower =~ "http" ]] && {
                is_json_add="$is_json_add,transport:{type:\"http\"}"
            } || {
                is_users=${is_users/uuid/flow:\"xtls-rprx-vision\",uuid}
            }
            ;;
        *http* | *h2*)
            net=http
            [[ $is_lower =~ "up" ]] && net=httpupgrade
            is_json_add="transport:{type:\"$net\"$is_path_host_json}"
            [[ $is_lower =~ "h2" || ! $is_lower =~ "httpupgrade" && $host ]] && {
                net=h2
                is_json_add="${is_tls_json/alpn\:\[\"h3\"\],/},$is_json_add"
            }
            ;;
        *)
            err "無法識別傳輸協議: $is_config_file"
            ;;
        esac
        json_str="$is_users,$is_json_add"
        ;;
    host-test) # test host dns record; for auto *tls required.
        [[ $is_no_auto_tls || $is_gen || $is_dont_test_host ]] && return
        get_ip
        get ping
        if [[ ! $(grep $ip <<<$is_host_dns) ]]; then
            msg "\n請將 ($(_red $host)) 解析到 ($(_red $ip))"
            msg "\n如果使用 Cloudflare, 在 DNS 那; 關閉 (Proxy status / 代理狀態), 即是 (DNS only / 僅限 DNS)"
            ask string y "我已经確定解析 [y]:"
            get ping
            if [[ ! $(grep $ip <<<$is_host_dns) ]]; then
                _bright "\n  $is_host_dns"
                err "域名 ($host) 没有解析到 ($ip)"
            fi
        fi
        ;;
    ssss | ss2022)
        if [[ $(grep 128 <<<$ss_method) ]]; then
            $is_core_bin generate rand 16 --base64
        else
            $is_core_bin generate rand 32 --base64
        fi
        ;;
    ping)
        # is_ip_type="-4"
        # [[ $(grep ":" <<<$ip) ]] && is_ip_type="-6"
        # is_host_dns=$(ping $host $is_ip_type -c 1 -W 2 | head -1)
        is_dns_type="a"
        [[ $(grep ":" <<<$ip) ]] && is_dns_type="aaaa"
        is_host_dns=$(_wget -qO- --header="accept: application/dns-json" "https://one.one.one.one/dns-query?name=$host&type=$is_dns_type")
        ;;
    install-caddy)
        _bright "\n>> installing Caddy for auto TLS\n"
        load download.sh
        download caddy
        load systemd.sh
        install_service caddy &>/dev/null
        is_caddy=1
        _bright ">> Caddy installed\n"
        ;;
    reinstall)
        is_install_sh=$(cat $is_sh_dir/install.sh)
        uninstall
        bash <<<$is_install_sh
        ;;
    test-run)
        if [[ $is_systemd ]]; then
            systemctl list-units --full -all &>/dev/null
            [[ $? != 0 ]] && {
                _dim "\n>> systemctl unavailable, skip test\n"
                return
            }
        fi
        is_no_manage_msg=1
        if [[ ! $(pgrep -f $is_core_bin) ]]; then
            _dim ">> testing $is_core_name"
            manage start &>/dev/null
            if [[ $is_run_fail == $is_core ]]; then
                _red "$is_core_name 執行失敗資訊:"
                $is_core_bin run -c $is_config_json -C $is_conf_dir
            else
                _bright ">> $is_core_name started"
            fi
        else
            _bright ">> $is_core_name already running"
        fi
        if [[ $is_caddy ]]; then
            if [[ ! $(pgrep -f $is_caddy_bin) ]]; then
                _dim "\n>> testing Caddy\n"
                manage start caddy &>/dev/null
                if [[ $is_run_fail == 'caddy' ]]; then
                    _red "Caddy 執行失敗資訊:"
                    $is_caddy_bin run --config $is_caddyfile
                else
                    _bright "\n>> Caddy started\n"
                fi
            else
                _bright "\n>> Caddy already running\n"
            fi
        fi
        ;;
    esac
}

# show info
info() {
    if [[ ! $is_protocol ]]; then
        get info $1
    fi
    case $net in
    ws | tcp | h2 | quic | http*)
        if [[ $host ]]; then
            is_can_change=(0 1 2 3 5)
            is_info_show=(0 1 2 3 4 6 7 8)
            [[ $is_protocol == 'vmess' ]] && {
                is_vmess_url=$(jq -c '{v:2,ps:'\"WAHSUN-$net-$host\"',add:'\"$is_addr\"',port:'\"$is_https_port\"',id:'\"$uuid\"',aid:\"0\",net:'\"$net\"',host:'\"$host\"',path:'\"$path\"',tls:'\"tls\"'}' <<<{})
                is_url=vmess://$(echo -n $is_vmess_url | base64 -w 0)
            } || {
                [[ $is_protocol == "trojan" ]] && {
                    uuid=$password
                    # is_info_str=($is_protocol $is_addr $is_https_port $password $net $host $path 'tls')
                    is_can_change=(0 1 2 3 4)
                    is_info_show=(0 1 2 10 4 6 7 8)
                }
                is_url="$is_protocol://$uuid@$host:$is_https_port?encryption=none&security=tls&type=$net&host=$host&path=$path#WAHSUN-$net-$host"
            }
            [[ $is_caddy ]] && is_can_change+=(11)
            is_info_str=($is_protocol $is_addr $is_https_port $uuid $net $host $path 'tls')
        else
            is_type=none
            is_can_change=(0 1 5)
            is_info_show=(0 1 2 3 4)
            is_info_str=($is_protocol $is_addr $port $uuid $net)
            [[ $net == "http" ]] && {
                net=tcp
                is_type=http
                is_tcp_http=1
                is_info_show+=(5)
                is_info_str=(${is_info_str[@]/http/tcp http})
            }
            [[ $net == "quic" ]] && {
                is_insecure=1
                is_info_show+=(8 9 20)
                is_info_str+=(tls h3 true)
                is_quic_add=",tls:\"tls\",alpn:\"h3\"" # cant add allowInsecure
            }
            is_vmess_url=$(jq -c "{v:2,ps:\"WAHSUN-${net}-$is_addr\",add:\"$is_addr\",port:\"$port\",id:\"$uuid\",aid:\"0\",net:\"$net\",type:\"$is_type\"$is_quic_add}" <<<{})
            is_url=vmess://$(echo -n $is_vmess_url | base64 -w 0)
        fi
        ;;
    ss)
        is_can_change=(0 1 4 6)
        is_info_show=(0 1 2 10 11)
        is_url="ss://$(echo -n ${ss_method}:${ss_password} | base64 -w 0)@${is_addr}:${port}#WAHSUN-$net-${is_addr}"
        is_info_str=($is_protocol $is_addr $port $ss_password $ss_method)
        ;;
    trojan)
        is_insecure=1
        is_can_change=(0 1 4)
        is_info_show=(0 1 2 10 4 8 20)
        is_url="$is_protocol://$password@$is_addr:$port?type=tcp&security=tls&insecure=1&allowInsecure=1#WAHSUN-$net-$is_addr"
        is_info_str=($is_protocol $is_addr $port $password tcp tls true)
        ;;
    hy*)
        is_can_change=(0 1 4)
        is_info_show=(0 1 2 10 8 9 20)
        # fix xray core for client use.
        is_sha256=$(openssl x509 -noout -fingerprint -sha256 -in $is_core_dir/bin/tls.cer | sed 's/.*=//;s/://g')
        is_url="$is_protocol://$password@$is_addr:$port?alpn=h3&insecure=1&allowInsecure=1&pinSHA256=$is_sha256#WAHSUN-$net-$is_addr"
        is_info_str=($is_protocol $is_addr $port $password tls h3 "true (設置, 固定證書>證書指紋(SHA-256): $is_sha256)")
        ;;
    tuic)
        is_insecure=1
        is_can_change=(0 1 4 5)
        is_info_show=(0 1 2 3 10 8 9 20 21)
        is_url="$is_protocol://$uuid:$password@$is_addr:$port?alpn=h3&insecure=1&allowInsecure=1&congestion_control=bbr#WAHSUN-$net-$is_addr"
        is_info_str=($is_protocol $is_addr $port $uuid $password tls h3 true bbr)
        ;;
    reality)
        is_color=41
        is_can_change=(0 1 5 9 10)
        is_info_show=(0 1 2 3 15 4 8 16 17 18)
        is_flow=xtls-rprx-vision
        is_net_type=tcp
        [[ $net_type =~ "http" || ${is_new_protocol,,} =~ "http" ]] && {
            is_flow=
            is_net_type=h2
            is_info_show=(${is_info_show[@]/15/})
        }
        is_info_str=($is_protocol $is_addr $port $uuid $is_flow $is_net_type reality $is_servername chrome $is_public_key)
        is_url="$is_protocol://$uuid@$is_addr:$port?encryption=none&security=reality&flow=$is_flow&type=$is_net_type&sni=$is_servername&pbk=$is_public_key&fp=chrome#WAHSUN-$net-$is_addr"
        ;;
    anytls)
        is_can_change=(0 1 4)
        if [[ $is_anytls_domain ]]; then
            is_info_show=(0 1 2 10 8)
            is_info_str=($is_protocol $is_anytls_domain $port $password tls)
            is_url="anytls://$password@$is_anytls_domain:$port#WAHSUN-$net-$is_anytls_domain"
        else
            is_insecure=1
            is_info_show=(0 1 2 10 8 20)
            is_info_str=($is_protocol $is_addr $port $password tls true)
            is_url="anytls://$password@$is_addr:$port?insecure=1&allowInsecure=1#WAHSUN-$net-$is_addr"
        fi
        ;;
    direct)
        is_can_change=(0 1 7 8)
        is_info_show=(0 1 2 13 14)
        is_info_str=($is_protocol $is_addr $port $door_addr $door_port)
        ;;
    socks)
        is_can_change=(0 1 12 4)
        is_info_show=(0 1 2 19 10)
        is_info_str=($is_protocol $is_addr $port $is_socks_user $is_socks_pass)
        is_url="socks://$(echo -n ${is_socks_user}:${is_socks_pass} | base64 -w 0)@${is_addr}:${port}#WAHSUN-$net-${is_addr}"
        ;;
    esac
    [[ $is_dont_show_info || $is_gen || $is_dont_auto_exit ]] && return # dont show info
    _dim " > ${is_config_name%.json}"
    for ((i = 0; i < ${#is_info_show[@]}; i++)); do
        a=${info_list[${is_info_show[$i]}]}
        printf " ${c_dim}%s${c_none} ${c_bright}%s${c_none}\n" "$a" "${is_info_str[$i]}"
    done
    if [[ $is_new_install ]]; then
        warn "首次安裝請查看腳本幫助文档: $(msg_ul https://doc.wahsun.org/$is_core/$is_core-script/)"
    fi
    if [[ $is_url ]]; then
        _dim " > URL"
        msg " ${c_bright}${is_url}${c_none}"
        [[ $is_insecure ]] && {
            warn "部份客戶端（如 V2rayN 等）匯入 URL 時需手動將：跳過證書驗證 (allowInsecure) 設定為 true，或開啟：允許不安全的連線"
        }
    fi
    if [[ $is_no_auto_tls ]]; then
        _dim " > no-auto-tls"
        msg " 端口(port): $port"
        msg " 路徑(path): $path"
    fi
    _dim " >"
}

# footer msg
footer_msg() {
    [[ $is_core_stop && ! $is_new_json ]] && warn "$is_core_name $L_STOPPED_MSG"
    [[ $is_caddy_stop && $host ]] && warn "Caddy $L_STOPPED_MSG"
}

# URL or qrcode
url_qr() {
    is_dont_show_info=1
    info $2
    if [[ $is_url ]]; then
        [[ $1 == 'url' ]] && {
            _dim " > URL: ${is_config_name%.json}"
            msg " ${c_bright}${is_url}${c_none}"
            footer_msg
        } || {
            link="https://c92d58.github.io/tools/qr.html#${is_url}"
            _dim " > QR: ${is_config_name%.json}"
            msg
            if [[ $(type -P qrencode) ]]; then
                qrencode -t ANSI "${is_url}"
            else
                msg "  install qrencode: $(_bright $cmd install qrencode)"
            fi
            msg
            msg "如果無法正常顯示或識別, 請使用下面的連結來生成二維碼:"
            msg " ${c_bright}${link}${c_none}"
            footer_msg
        }
    else
        [[ $1 == 'url' ]] && {
            err "($is_config_name) 無法生成 URL 連結."
        } || {
            err "($is_config_name) 無法生成 QR code 二維碼."
        }
    fi
}

# update core, sh, caddy
update() {
    case $1 in
    1 | core | $is_core)
        is_update_name=core
        is_show_name=$is_core_name
        is_run_ver=v${is_core_ver##* }
        is_update_repo=$is_core_repo
        ;;
    2 | sh)
        is_update_name=sh
        is_show_name="$is_core_name 腳本"
        is_run_ver=$is_sh_ver
        is_update_repo=$is_sh_repo
        ;;
    3 | caddy)
        [[ ! $is_caddy ]] && err "不支援更新 Caddy."
        is_update_name=caddy
        is_show_name="Caddy"
        is_run_ver=$is_caddy_ver
        is_update_repo=$is_caddy_repo
        ;;
    *)
        err "無法識別 ($1), 請使用: $is_sh_name update [core | sh | caddy] [ver]"
        ;;
    esac
    [[ $2 ]] && is_new_ver=v${2#v}
    [[ $is_run_ver == $is_new_ver ]] && {
        msg "\n自定義版本和當前 $is_show_name 版本一样, 無需更新.\n"
        exit
    }
    load download.sh
    if [[ $is_new_ver ]]; then
        msg "  $(_bright "$is_show_name $is_new_ver")"
    else
        get_latest_version $is_update_name
        [[ $is_run_ver == $latest_ver ]] && {
            msg "\n$is_show_name 當前已经是最新版本了.\n"
            exit
        }
        msg "\n發現 $is_show_name 新版本: $(_bright $latest_ver)\n"
        is_new_ver=$latest_ver
    fi
    download $is_update_name $is_new_ver
    msg "  $(_bright $is_show_name $is_new_ver)"
    local release_url="https://github.com/$is_update_repo/releases/tag/$is_new_ver"
    msg "  $(_bright release notes: $release_url)"
    [[ $is_update_name != 'sh' ]] && manage restart $is_update_name &
}

# main menu — geek style, vertical
is_main_menu() {
    msg
    if [[ $is_sbx_splash == 0 ]]; then
        msg " ${c_bright}+-------------------------+${c_none}"; sleep 0.1
        msg " ${c_bright}|${c_none} sbx ${is_sh_ver}   ${is_core_status}   ${c_bright}|${c_none}"; sleep 0.12
        msg " ${c_bright}|${c_none} WAHSUN 2025-2026 MIT    ${c_bright}|${c_none}"; sleep 0.12
        msg " ${c_bright}+-------------------------+${c_none}"; sleep 0.1
        is_sbx_splash=1
    else
        msg " ${c_bright}+-------------------------+${c_none}"
        msg " ${c_bright}|${c_none} sbx ${is_sh_ver}   ${is_core_status}   ${c_bright}|${c_none}"
        msg " ${c_bright}|${c_none} WAHSUN 2025-2026 MIT    ${c_bright}|${c_none}"
        msg " ${c_bright}+-------------------------+${c_none}"
    fi
    show_menu_items
    echo -ne " ${c_bright}>>${c_none} "
    read -r REPLY
    [[ ! $REPLY ]] && return
    is_main_start=1

    local zh=0
    [[ -f $is_core_dir/lang ]] && grep -q 'zh-TW' $is_core_dir/lang 2>/dev/null && zh=1

    case $REPLY in
    1)  # config
        [[ $zh == 1 ]] && local items="add 添加" || local items="add" 
        [[ $zh == 1 ]] && items="$items change 更改" || items="$items change"
        [[ $zh == 1 ]] && items="$items view 查看" || items="$items view"
        [[ $zh == 1 ]] && items="$items delete 刪除" || items="$items delete"
        items="$items back 返回 exit 退出"
        menu_sub "config" "$items"
        case $REPLY in
        1) add ;; 2) change ;; 3) info ;; 4) del ;;
        b | B) return ;;
        e | E | q | Q | exit) msg && exit 0 ;;
        esac ;;
    2)  # dns
        load dns.sh
        [[ $zh == 1 ]] && menu_sub "dns" "nextdns NextDNS preset DNS預設 back 返回 exit 退出" || menu_sub "dns" "nextdns preset back exit"
        case $REPLY in
        1) dns_set_nextdns ;; 2) dns_set ;;
        b | B) return ;;
        e | E | q | Q | exit) msg && exit 0 ;;
        esac ;;
    3)  # tools
        [[ $zh == 1 ]] && menu_sub "tools" "speed 測速 health 檢查 backup 備份 traffic 流量 back 返回 exit 退出" || menu_sub "tools" "speed health backup traffic back exit"
        case $REPLY in
        1) load speed.sh; speed_set ;;
        2) load check.sh; check_set ;;
        3) load backup.sh; backup_set ;;
        4) load traffic.sh; traffic_set ;;
        b | B) return ;;
        e | E | q | Q | exit) msg && exit 0 ;;
        esac ;;
    4)  # system  
        [[ $zh == 1 ]] && menu_sub "system" "manage 管理 bbr BBR log 日誌 update 更新 reinstall 重裝 uninstall 卸載" || menu_sub "system" "manage bbr log update reinstall uninstall"
        case $REPLY in
        1) [[ $zh == 1 ]] && local mgmt="start 啟動 stop 停止 restart 重啟" || local mgmt="start stop restart"
           menu_sub "manage" "$mgmt"
           manage $REPLY & ;;
        2) load bbr.sh; _try_enable_bbr ;;
        3) load log.sh; log_set ;;
        4) [[ $zh == 1 ]] && menu_sub "update" "core 核心 script 腳本" || menu_sub "update" "core script"
           case $REPLY in
           1) update core ;;
           2) update sh ;;
           esac
           [[ $is_caddy ]] && update caddy ;;
        5) get reinstall ;;
        6) uninstall ;;
        esac ;;
    5)  # help
        [[ $zh == 1 ]] && menu_sub "help" "help 幫助 about 關於 lang 語言 back 返回 exit 退出" || menu_sub "help" "help about lang back exit"
        case $REPLY in
        1) load help.sh; show_help ;;
        2) load help.sh; about ;;
        3) _dim "  sbx lang zh-TW | sbx lang en" ;;
        b | B) return ;;
        e | E | q | Q | exit) msg && exit 0 ;;
        esac ;;
    m | M | matrix)
        load matrix.sh
        matrix_set
        ;;
    q | Q | quit | e | E | exit)
        msg "  bye!"
        exit 0
        ;;
    esac
}

show_menu_items() {
    if [[ -f $is_core_dir/lang && $(cat $is_core_dir/lang) == "zh-TW" ]]; then
        msg " ${c_dim}[1]${c_none} 配置     ${c_dim}[2]${c_none} DNS        ${c_dim}[3]${c_none} 工具"
        msg " ${c_dim}[4]${c_none} 系統     ${c_dim}[5]${c_none} 幫助       ${c_dim}[m]${c_none} 母體"
    else
        msg " ${c_dim}[1]${c_none} config   ${c_dim}[2]${c_none} dns        ${c_dim}[3]${c_none} tools"
        msg " ${c_dim}[4]${c_none} system   ${c_dim}[5]${c_none} help       ${c_dim}[m]${c_none} matrix"
    fi
}

menu_sub() {
    local title=$1; shift
    msg
    msg " ${c_bright}▐▌ ${c_dim}${title}${c_none}"
    msg " ${c_dim}----------------${c_none}"
    local i=1
    local is_zh=0
    [[ -f $is_core_dir/lang ]] && grep -q zh-TW $is_core_dir/lang && is_zh=1
    read -ra items <<< "$@"
    if [[ $is_zh == 1 ]]; then
        local idx=0
        while [[ $idx -lt ${#items[@]} ]]; do
            local cmd="${items[$idx]}"
            local label="${items[$((idx+1))]}"
            if [[ $label ]]; then
                msg " [$i] $label"
            else
                msg " [$i] $cmd"
            fi
            ((i++))
            idx=$((idx + 2))
        done
    else
        for cmd in "${items[@]}"; do
            msg " [$i] $cmd"
            ((i++))
        done
    fi
    echo -ne " ${c_bright}>${c_none} "
    read -r REPLY
}


# check prefer args, if not exist prefer args and show main menu
main() {
    case $1 in
    a | add | gen | no-auto-tls)
        [[ $1 == 'gen' ]] && is_gen=1
        [[ $1 == 'no-auto-tls' ]] && is_no_auto_tls=1
        add ${@:2}
        ;;
    backup)
        load backup.sh
        backup_set ${@:2}
        ;;
    check)
        load check.sh
        check_set ${@:2}
        ;;
    restore)
        load backup.sh
        restore_set $2
        ;;
    speed)
        load speed.sh
        speed_set ${@:2}
        ;;
    traffic)
        load traffic.sh
        traffic_set ${@:2}
        ;;
    bin | pbk | completion | format | generate | geoip | geosite | merge | rule-set | run | tools)
        is_run_command=$1
        if [[ $1 == 'bin' ]]; then
            $is_core_bin ${@:2}
        else
            [[ $is_run_command == 'pbk' ]] && is_run_command="generate reality-keypair"
            $is_core_bin $is_run_command ${@:2}
        fi
        ;;
    bbr)
        load bbr.sh
        _try_enable_bbr
        ;;
    c | config | change)
        change ${@:2}
        ;;
    # client | genc)
    #     create client $2
    #     ;;
    d | del | rm)
        del $2
        ;;
    dd | ddel | fix | fix-all)
        case $1 in
        fix)
            [[ $2 ]] && {
                change $2 full
            } || {
                is_change_id=full && change
            }
            return
            ;;
        fix-all)
            is_dont_auto_exit=1
            msg
            for v in $(ls $is_conf_dir | grep .json$ | sed '/dynamic-port-.*-link/d'); do
                msg "fix: $v"
                change $v full
            done
            _bright ">> fix done"
            ;;
        *)
            is_dont_auto_exit=1
            [[ ! $2 ]] && {
                err "無法找到需要刪除的參數"
            } || {
                for v in ${@:2}; do
                    del $v
                done
            }
            ;;
        esac
        is_dont_auto_exit=
        manage restart &
        [[ $is_del_host ]] && manage restart caddy &
        ;;
    dns)
        load dns.sh
        dns_set ${@:2}
        ;;
    matrix)
        load matrix.sh
        matrix_set ${@:2}
        ;;
    lang)
        case ${2,,} in
        zh-tw|zh)
            echo zh-TW >$is_core_dir/lang
            _bright ">> language: 繁體中文"
            ;;
        en|english)
            echo en >$is_core_dir/lang
            _bright ">> language: English"
            ;;
        *)
            _dim ">> usage: sbx lang zh-TW|en"
            ;;
        esac
        ;;
    debug)
        is_debug=1
        get info $2
        warn "如果需要複製; 請把 *uuid, *password, *host, *key 的值改寫, 以避免泄露."
        ;;
    fix-config.json)
        create config.json
        ;;
    fix-caddyfile)
        if [[ $is_caddy ]]; then
            load caddy.sh
            caddy_config new
            manage restart caddy &
            _bright ">> fix done"
        else
            err "無法執行此操作"
        fi
        ;;
    i | info)
        info $2
        ;;
    ip)
        get_ip
        msg $ip
        ;;
    in | import)
        load import.sh
        ;;
    log)
        load log.sh
        log_set $2
        ;;
    url | qr)
        url_qr $@
        ;;
    un | uninstall)
        uninstall
        ;;
    u | up | update | U | update.sh)
        is_update_name=$2
        is_update_ver=$3
        [[ ! $is_update_name ]] && is_update_name=core
        [[ $1 == 'U' || $1 == 'update.sh' ]] && {
            is_update_name=sh
            is_update_ver=
        }
        update $is_update_name $is_update_ver
        ;;
    ssss | ss2022)
        get $@
        ;;
    s | status)
        msg "\n$is_core_name $is_core_ver: $is_core_status\n"
        [[ $is_caddy ]] && msg "Caddy $is_caddy_ver: $is_caddy_status\n"
        ;;
    start | stop | r | restart)
        [[ $2 && $2 != 'caddy' ]] && err "無法識別 ($2), 請使用: $is_sh_name $1 [caddy]"
        manage $1 $2 &
        ;;
    t | test)
        get test-run
        ;;
    reinstall)
        get $1
        ;;
    get-port)
        get_port
        msg $tmp_port
        ;;
    main)
        is_sbx_splash=0
        while :; do
            is_main_menu
        done
        ;;
    v | ver | version)
        [[ $is_caddy_ver ]] && is_caddy_ver=" / ${c_bright}$is_caddy_ver${c_none}"
        msg
        msg " ${c_bright}+--------------------------------+${c_none}"
        msg " ${c_bright}|${c_none}  ${c_bright}sbx ${is_sh_ver}${c_none}                     ${c_bright}|${c_none}"
        msg " ${c_bright}|${c_none}  ${c_dim}sing-box${c_none} ${is_core_ver}${is_caddy_ver}         ${c_bright}|${c_none}"
        msg " ${c_bright}|${c_none}  ${c_dim}WAHSUN${c_none}                        ${c_bright}|${c_none}"
        msg " ${c_bright}+--------------------------------+${c_none}"
        ;;
    h | help | --help)
        load help.sh
        show_help ${@:2}
        ;;
    *)
        is_try_change=1
        change test $1
        if [[ $is_change_id ]]; then
            unset is_try_change
            [[ $2 ]] && {
                change $2 $1 ${@:3}
            } || {
                change
            }
        else
            err "無法識別 ($1), 獲取幫助請使用: $is_sh_name help"
        fi
        ;;
    esac
}
