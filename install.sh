#!/bin/bash

author=WAHSUN
# github=https://github.com/c92d58/sing-box

# MATRIX palette — all green on black
c_bright='\e[92m'
c_green='\e[32m'
c_dim='\e[2m\e[32m'
c_red='\e[91m'
c_none='\e[0m'

_bright() { echo -e ${c_bright}$@${c_none}; }
_green()  { echo -e ${c_green}$@${c_none}; }
_dim()    { echo -e ${c_dim}$@${c_none}; }
_red()    { echo -e ${c_red}$@${c_none}; }

is_err=$(_red "[!]")
is_warn=$(_dim "[-]")

err() {
    echo -e "\n ${c_red}[!]${c_none} $@\n" && exit 1
}

warn() {
    echo -e "\n ${c_dim}[-]${c_none} $@\n"
}

# root
[[ $EUID != 0 ]] && err "當前非 $(_dim "root required") 執行."

# apt-get, yum, zypper or apk
cmd=$(type -P apt-get || type -P yum || type -P zypper || type -P apk)
[[ ! $cmd ]] && err "此腳本僅支援 $(_dim "Ubuntu/Debian/CentOS/SUSE/Alpine")."

# systemd or openrc
is_systemd=$(type -P systemctl)
is_openrc=$(type -P rc-service)
[[ ! $is_systemd && ! $is_openrc ]] && {
    err "此系統缺少 $(_dim "systemctl/rc-service") 不存在, 請安裝 systemd 或確認 OpenRC 已啟用."
}

# wget installed or none
is_wget=$(type -P wget)

# x64
case $(uname -m) in
amd64 | x86_64)
    is_arch=amd64
    ;;
*aarch64* | *armv8*)
    is_arch=arm64
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
is_pkg="wget tar bash"
# Alpine: gcompat provides glibc compatibility for prebuilt binaries
[[ $cmd =~ apk ]] && is_pkg="$is_pkg gcompat jq"
is_config_json=$is_core_dir/config.json
tmp_var_lists=(
    tmpcore
    tmpsh
    tmpjq
    is_core_ok
    is_sh_ok
    is_jq_ok
    is_pkg_ok
)

# tmp dir
tmpdir=$(mktemp -d)
[[ ! $tmpdir ]] && {
    tmpdir=/tmp/tmp-$RANDOM
    mkdir -p $tmpdir
}

# set up var
for i in ${tmp_var_lists[*]}; do
    export $i=$tmpdir/$i
done

# load bash script — resolves module paths
load() {
    local mod_path
    case $1 in
        dispatcher.sh|json.sh|theme.sh|plugin.sh|logger.sh) mod_path="core/$1" ;;
        dns.sh|speed.sh)                     mod_path="modules/network/$1" ;;
        systemd.sh|caddy.sh|bbr.sh)          mod_path="modules/service/$1" ;;
        backup.sh|check.sh|traffic.sh|log.sh|import.sh|download.sh|help.sh|doctor.sh|bench.sh|profile.sh) mod_path="modules/tools/$1" ;;
        dashboard.sh|matrix.sh|theme_ui.sh)  mod_path="modules/ui/$1" ;;
        *) mod_path="src/$1" ;;
    esac
    . $is_sh_dir/$mod_path
}

# wget add --no-check-certificate
_wget() {
    [[ $proxy ]] && export https_proxy=$proxy
    wget --no-check-certificate $*
}

# print a mesage
msg() {
    case $1 in
    warn)
        local color=$c_dim
        ;;
    err)
        local color=$c_red
        ;;
    ok)
        local color=$c_bright
        ;;
    esac

    echo -e "${color}$(date +'%T')${c_none}) ${2}"
}

# show help msg
show_help() {
    echo -e "Usage: $0 [-f xxx | -l | -p xxx | -v xxx | -h]"
    echo -e "  -f, --core-file <path>          自定義 $is_core_name 檔案路徑, e.g., -f /root/$is_core-linux-amd64.tar.gz"
    echo -e "  -l, --local-install             本地獲取安裝腳本, 使用當前目錄"
    echo -e "  -p, --proxy <addr>              使用代理下載, e.g., -p http://127.0.0.1:2333"
    echo -e "  -v, --core-version <ver>        自定義 $is_core_name 版本, e.g., -v v1.8.13"
    echo -e "  -h, --help                      顯示此幫助界面\n"

    exit 0
}

# install dependent pkg
install_pkg() {
    cmd_not_found=
    for i in $*; do
        [[ ! $(type -P $i) ]] && cmd_not_found="$cmd_not_found,$i"
    done
    if [[ $cmd_not_found ]]; then
        pkg=$(echo $cmd_not_found | sed 's/,/ /g')
        msg warn "安裝依赖包 >${pkg}"
        if [[ $cmd =~ apk ]]; then
            apk update &>/dev/null
            apk add $pkg &>/dev/null
        else
            $cmd install -y $pkg &>/dev/null
            if [[ $? != 0 ]]; then
                [[ $cmd =~ yum ]] && yum install epel-release -y &>/dev/null
                if [[ $cmd =~ zypper ]]; then
                    $cmd --non-interactive refresh &>/dev/null
                else
                    $cmd update -y &>/dev/null
                fi
                $cmd install -y $pkg &>/dev/null
            fi
        fi
        [[ $? == 0 ]] && >$is_pkg_ok
    else
        >$is_pkg_ok
    fi
}

# download file
download() {
    case $1 in
    core)
        [[ ! $is_core_ver ]] && is_core_ver=$(_wget -qO- "https://api.github.com/repos/${is_core_repo}/releases/latest?v=$RANDOM" | grep tag_name | grep -E -o 'v([0-9.]+)')
        [[ $is_core_ver ]] && link="https://github.com/${is_core_repo}/releases/download/${is_core_ver}/${is_core}-${is_core_ver:1}-linux-${is_arch}.tar.gz"
        name=$is_core_name
        tmpfile=$tmpcore
        is_ok=$is_core_ok
        ;;
    sh)
        link=https://github.com/${is_sh_repo}/archive/main.tar.gz
        name="$is_sh_name 腳本"
        tmpfile=$tmpsh
        is_ok=$is_sh_ok
        ;;
    jq)
        link=https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-$is_arch
        name="jq"
        tmpfile=$tmpjq
        is_ok=$is_jq_ok
        ;;
    esac

    [[ $link ]] && {
        msg warn "下載 ${name} > ${link}"
        if _wget -t 3 -q -c $link -O $tmpfile; then
            mv -f $tmpfile $is_ok
        fi
    }
}

# get server ip
get_ip() {
    ip=$(_wget -4 -qO- https://one.one.one.one/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p')
    [[ -z $ip ]] && ip=$(_wget -6 -qO- https://one.one.one.one/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p')
}

# check background tasks status
check_status() {
    # dependent pkg install fail
    [[ ! -f $is_pkg_ok ]] && {
        msg err "安裝依赖包失敗"
        if [[ $cmd =~ apk ]]; then
            msg err "請嘗試手動安裝依赖包: apk update; apk add $is_pkg"
        else
            msg err "請嘗試手動安裝依赖包: $cmd update -y; $cmd install -y $is_pkg"
        fi
        is_fail=1
    }

    # download file status
    if [[ $is_wget ]]; then
        [[ ! -f $is_core_ok ]] && {
            msg err "下載 ${is_core_name} 失敗"
            is_fail=1
        }
        [[ ! -f $is_sh_ok ]] && {
            msg err "下載 ${is_sh_name} 腳本失敗"
            is_fail=1
        }
        [[ ! -f $is_jq_ok ]] && {
            msg err "下載 jq 失敗"
            is_fail=1
        }
    else
        [[ ! $is_fail ]] && {
            is_wget=1
            [[ ! $is_core_file ]] && download core &
            [[ ! $local_install ]] && download sh &
            [[ $jq_not_found ]] && download jq &
            get_ip
            wait
            check_status
        }
    fi

    # found fail status, remove tmp dir and exit.
    [[ $is_fail ]] && {
        exit_and_del_tmpdir
    }
}

# parameters check
pass_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -f | --core-file)
            [[ -z $2 ]] && {
                err "($1) 缺少必需參數, 正確使用示例: [$1 /root/$is_core-linux-amd64.tar.gz]"
            } || [[ ! -f $2 ]] && {
                err "($2) 不是一個常規的檔案."
            }
            is_core_file=$2
            shift 2
            ;;
        -l | --local-install)
            [[ ! -f ${PWD}/core/dispatcher.sh || ! -f ${PWD}/$is_sh_name.sh ]] && {
                err "當前目錄 (${PWD}) 非完整的腳本目錄."
            }
            local_install=1
            shift 1
            ;;
        -p | --proxy)
            [[ -z $2 ]] && {
                err "($1) 缺少必需參數, 正確使用示例: [$1 http://127.0.0.1:2333 or -p socks5://127.0.0.1:2333]"
            }
            proxy=$2
            shift 2
            ;;
        -v | --core-version)
            [[ -z $2 ]] && {
                err "($1) 缺少必需參數, 正確使用示例: [$1 v1.8.13]"
            }
            is_core_ver=v${2//v/}
            shift 2
            ;;
        -h | --help)
            show_help
            ;;
        *)
            echo -e "\n${is_err} ($@) 為未知參數...\n"
            show_help
            ;;
        esac
    done
    [[ $is_core_ver && $is_core_file ]] && {
        err "無法同时自定義 ${is_core_name} 版本和 ${is_core_name} 檔案."
    }
}

# exit and remove tmpdir
exit_and_del_tmpdir() {
    rm -rf $tmpdir
    [[ ! $1 ]] && {
        msg err "install failed"
        msg err "安裝過程出現錯誤..."
        echo -e "反饋問題) https://github.com/${is_sh_repo}/issues"
        echo
        exit 1
    }
    exit
}

# main
main() {

    # check old version
    [[ -f $is_sh_bin && -d $is_core_dir/bin && -d $is_sh_dir && -d $is_conf_dir ]] && {
        err "檢測到腳本已安裝, 如需重裝請使用 $(_bright "$is_sh_name reinstall") 命令."
    }

    # check parameters
    [[ $# -gt 0 ]] && pass_args $@

    # show welcome msg
    clear
    echo
    _bright "  sbx installer"
    _dim   "  Next Generation sing-box Manager"
    echo
    _dim   "  ──────────────────────────────"
    echo -e "  ${c_bright}By: WAHSUN${c_none}"
    echo

    # language selection (hardcoded - language packs not available during pipe install)
    echo "  1) 繁體中文"
    echo "  2) English"
    echo -ne "  select [1/2]: "
    read -r lang_choice
    case $lang_choice in
    1) is_lang="zh-TW" ;;
    *) is_lang="en" ;;
    esac
    # write language to config dir (created later in install)
    echo $is_lang >$tmpdir/lang
    msg ok "install started"
    [[ $is_core_ver ]] && msg warn "$(_dim "$is_core_name $is_core_ver")"
    [[ $proxy ]] && msg warn "$(_dim "proxy $proxy")"
    # create tmpdir
    mkdir -p $tmpdir
    # if is_core_file, copy file
    [[ $is_core_file ]] && {
        cp -f $is_core_file $is_core_ok
        msg warn "$(_dim "file $is_core_file")"
    }
    # local dir install sh script
    [[ $local_install ]] && {
        >$is_sh_ok
        msg warn "$(_dim "local $PWD")"
    }

    if [[ $is_systemd ]]; then
        timedatectl set-ntp true &>/dev/null
        [[ $? != 0 ]] && {
            is_ntp_on=1
        }
    fi

    # install dependent pkg
    if [[ $cmd =~ apk ]]; then
        # Alpine: force install full versions to replace BusyBox applets
        apk update &>/dev/null
        apk add $is_pkg &>/dev/null
        [[ $? == 0 ]] && >$is_pkg_ok
    else
        install_pkg $is_pkg &
    fi

    # jq
    if [[ $(type -P jq) ]]; then
        >$is_jq_ok
    else
        jq_not_found=1
    fi
    # if wget installed. download core, sh, jq, get ip
    [[ $is_wget ]] && {
        [[ ! $is_core_file ]] && download core &
        [[ ! $local_install ]] && download sh &
        [[ $jq_not_found ]] && download jq &
        get_ip
    }

    # waiting for background tasks is done
    wait

    # check background tasks status
    check_status

    # test $is_core_file
    if [[ $is_core_file ]]; then
        mkdir -p $tmpdir/testzip
        tar zxf $is_core_ok --strip-components 1 -C $tmpdir/testzip &>/dev/null
        [[ $? != 0 ]] && {
            msg err "${is_core_name} 檔案無法通過測試."
            exit_and_del_tmpdir
        }
        [[ ! -f $tmpdir/testzip/$is_core ]] && {
            msg err "${is_core_name} 檔案無法通過測試."
            exit_and_del_tmpdir
        }
    fi

    # get server ip.
    [[ ! $ip ]] && {
        msg err "獲取服務器 IP 失敗."
        exit_and_del_tmpdir
    }

    # create sh dir...
    mkdir -p $is_sh_dir

    # copy sh file or unzip sh zip file.
    if [[ $local_install ]]; then
        cp -rf $PWD/* $is_sh_dir
    else
        mkdir -p $tmpdir/sh
        tar zxf $is_sh_ok --strip-components 1 -C $tmpdir/sh
        cp -rf $tmpdir/sh/* $is_sh_dir
    fi

    # create core bin dir
    mkdir -p $is_core_dir/bin
    # copy core file or unzip core zip file
    if [[ $is_core_file ]]; then
        cp -rf $tmpdir/testzip/* $is_core_dir/bin
    else
        tar zxf $is_core_ok --strip-components 1 -C $is_core_dir/bin
    fi

    # add alias: sb = sbx
    echo "alias sb=$is_sh_bin" >>/root/.bashrc
    echo "alias $is_sh_name=$is_sh_bin" >>/root/.bashrc

    # core command: sbx -> script
    ln -sf $is_sh_dir/$is_sh_name.sh $is_sh_bin
    ln -sf $is_sh_dir/$is_sh_name.sh ${is_sh_bin/$is_sh_name/sb}

    # jq
    [[ $jq_not_found ]] && mv -f $is_jq_ok /usr/bin/jq

    # chmod
    chmod +x $is_core_bin $is_sh_bin /usr/bin/jq ${is_sh_bin/$is_sh_name/sb}

    # create log dir
    mkdir -p $is_log_dir

    # show a tips msg
    msg ok "生成配置檔案..."

    # create service
    load systemd.sh
    is_new_install=1
    install_service $is_core &>/dev/null

    # create conf dir
    mkdir -p $is_conf_dir

    # write language choice
    [[ -f $tmpdir/lang ]] && cp $tmpdir/lang $is_core_dir/lang

    load dispatcher.sh
    # create a reality config
    add reality
    # wait for background tasks (e.g., OpenRC service start)
    wait
    # remove tmp dir and exit.
    exit_and_del_tmpdir ok
}

# start.
main $@
