#!/bin/bash

author=WAHSUN
# github=https://github.com/c92d58/sing-box

# MATRIX palette — all green on black
c_bright='\e[92m'          # bright green  — primary text / highlights
c_green='\e[32m'           # green         — body text
c_dim='\e[2m\e[32m'        # dim green     — decorations / hints
c_red='\e[91m'             # bright red    — ONLY critical errors
c_none='\e[0m'

_bright() { echo -e ${c_bright}$@${c_none}; }
_green()  { echo -e ${c_green}$@${c_none}; }
_dim()    { echo -e ${c_dim}$@${c_none}; }
_red()    { echo -e ${c_red}$@${c_none}; }

_rm() {
    rm -rf "$@"
}
_cp() {
    cp -rf "$@"
}
_sed() {
    sed -i "$@"
}
_mkdir() {
    mkdir -p "$@"
}

is_err=$(_red "[!]")
is_warn=$(_dim "[-]")

err() {
    echo -e "\n ${c_red}[!]${c_none} $@\n"
    [[ $is_dont_auto_exit || $is_dashboard ]] && return
    exit 1
}

warn() {
    echo -e "\n ${c_dim}[-]${c_none} $@\n"
}

# load bash script — resolves module paths
load() {
    local mod_path
    case $1 in
        # core modules
        dispatcher.sh|json.sh|theme.sh|plugin.sh|logger.sh) mod_path="core/$1" ;;
        # network modules
        speed.sh)                            mod_path="modules/network/$1" ;;
        # service modules
        systemd.sh|caddy.sh|bbr.sh)          mod_path="modules/service/$1" ;;
        # tools modules
        backup.sh|check.sh|traffic.sh|log.sh|import.sh|download.sh|help.sh|doctor.sh|bench.sh|profile.sh) mod_path="modules/tools/$1" ;;
        # ui modules
        dashboard.sh|matrix.sh|theme_ui.sh)  mod_path="modules/ui/$1" ;;
        # legacy fallback
        *) mod_path="src/$1" ;;
    esac
    . $is_sh_dir/$mod_path
}

# wget add --no-check-certificate
_wget() {
    [[ $proxy ]] && export https_proxy=$proxy
    # private repo: use GITHUB_TOKEN to authenticate raw/archive downloads
    if [[ $GITHUB_TOKEN ]]; then
        wget --no-check-certificate --header="Authorization: token $GITHUB_TOKEN" "$@"
    else
        wget --no-check-certificate "$@"
    fi
}

# apt-get, yum, zypper or apk
cmd=$(type -P apt-get || type -P yum || type -P zypper || type -P apk)

# x64
case $(uname -m) in
amd64 | x86_64)
    is_arch="amd64"
    ;;
*aarch64* | *armv8*)
    is_arch="arm64"
    ;;
*)
    err "此腳本僅支援 64 位系統..."
    ;;
esac

is_core=sing-box
is_core_name=sing-box
is_sh_name=sbx
is_core_dir=/etc/$is_sh_name
is_core_bin=$is_core_dir/bin/$is_core
is_core_repo=SagerNet/$is_core
is_conf_dir=$is_core_dir/conf
is_log_dir=/var/log/$is_sh_name
is_sh_bin=/usr/local/bin/$is_sh_name
is_sh_dir=$is_core_dir/sh
is_sh_repo=c92d58/$is_sh_name
THEME_DIR=$is_sh_dir/themes
PLUGIN_DIR=$is_sh_dir/plugins
PROFILE_DIR=$is_sh_dir/profiles
is_pkg="wget unzip tar qrencode bash"
is_config_json=$is_core_dir/config.json
is_caddy_bin=/usr/local/bin/caddy
is_caddy_dir=/etc/caddy
is_caddy_repo=caddyserver/caddy
is_caddyfile=$is_caddy_dir/Caddyfile
is_caddy_conf=$is_caddy_dir/$author
is_systemd=$(type -P systemctl)
is_openrc=$(type -P rc-service)
if [[ $is_systemd ]]; then
    is_caddy_service=$(systemctl list-units --full -all | grep caddy.service)
elif [[ $is_openrc ]]; then
    [[ -f /etc/init.d/caddy ]] && is_caddy_service=1
fi
is_http_port=80
is_https_port=443

# core ver (normalize: strip leading 'v' if present)
is_core_ver=$($is_core_bin version | head -n1 | cut -d " " -f3)
is_core_ver=${is_core_ver#v}

# tmp tls key
is_tls_cer=$is_core_dir/bin/tls.cer
is_tls_key=$is_core_dir/bin/tls.key
[[ ! -f $is_tls_cer || ! -f $is_tls_key ]] && {
    is_tls_tmp=${is_tls_key/key/tmp}
    $is_core_bin generate tls-keypair tls -m 456 >$is_tls_tmp
    awk '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/' $is_tls_tmp >$is_tls_key
    awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' $is_tls_tmp >$is_tls_cer
    rm $is_tls_tmp
}

if [[ $(pgrep -f $is_core_bin) ]]; then
    is_core_status=$(_bright ">> running")
else
    is_core_status=$(_dim ">> stopped")
    is_core_stop=1
fi
if [[ -f $is_caddy_bin && -d $is_caddy_dir && $is_caddy_service ]]; then
    is_caddy=1
    if [[ $is_systemd ]]; then
        [[ -f /lib/systemd/system/caddy.service && ! $(grep '\-\-adapter caddyfile' /lib/systemd/system/caddy.service) ]] && {
            load systemd.sh
            install_service caddy
            systemctl restart caddy &
        }
    fi
    is_caddy_ver=$($is_caddy_bin version | head -n1 | cut -d " " -f1)
    is_tmp_http_port=$(grep -E '^ {2,}http_port|^http_port' $is_caddyfile | grep -E -o [0-9]+)
    is_tmp_https_port=$(grep -E '^ {2,}https_port|^https_port' $is_caddyfile | grep -E -o [0-9]+)
    [[ $is_tmp_http_port ]] && is_http_port=$is_tmp_http_port
    [[ $is_tmp_https_port ]] && is_https_port=$is_tmp_https_port
    if [[ $(pgrep -f $is_caddy_bin) ]]; then
        is_caddy_status=$(_bright ">> running")
    else
        is_caddy_status=$(_dim ">> stopped")
        is_caddy_stop=1
    fi
fi

# Load language
is_lang_file=$is_core_dir/lang
if [[ -f $is_lang_file ]]; then
    . $is_sh_dir/lang/$(cat $is_lang_file).sh
else
    . $is_sh_dir/lang/en.sh
fi

# Load theme
is_theme_file=$is_core_dir/theme
[[ -f $is_theme_file ]] && is_theme=$(cat $is_theme_file) || is_theme="matrix"
if [[ -f $is_sh_dir/themes/${is_theme}.sh ]]; then
    . $is_sh_dir/themes/${is_theme}.sh
fi

load dispatcher.sh
[[ ! $args ]] && args=main
main $args
