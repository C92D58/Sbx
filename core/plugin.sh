# plugin.sh — sbx plugin system
#   sbx plugin list             list installed plugins
#   sbx plugin <name> [cmd]     run a plugin command

plugin_main() {
    case ${1,,} in
        list|ls|"") plugin_list ;;
        install|add) plugin_install "$2" ;;
        remove|delete|rm|del) plugin_remove "$2" ;;
        *) plugin_dispatch "$@" ;;
    esac
}

# ── Route subcommands to individual plugins ─────────────────
plugin_dispatch() {
    local name="${1,,}"
    local cmd="${2,,}"
    local plugin_file="$PLUGIN_DIR/$name/plugin.sh"

    [[ -f "$plugin_file" ]] || {
        echo
        _dim "  plugin '$name' not found"
        echo -e "  ${c_dim}available:${c_none}"
        for d in "$PLUGIN_DIR"/*/; do
            [[ -f "$d/plugin.sh" ]] && echo -e "  ${c_dim}$(basename "$d")${c_none}"
        done
        echo
        return
    }

    . "$plugin_file"

    # Look for plugin's main entry: <name>_main
    local entry_fn="${name}_main"
    if declare -f "$entry_fn" &>/dev/null; then
        "$entry_fn" "${@:2}"
    else
        # Fallback: show plugin info
        echo
        . "$plugin_file"
        printf "  ${c_bright}name:${c_none}        %s\n" "$(plugin_info | cut -d'|' -f1)"
        printf "  ${c_dim}version:${c_none}     %s\n" "$(plugin_info | cut -d'|' -f2)"
        printf "  ${c_dim}description:${c_none} %s\n" "$(plugin_info | cut -d'|' -f3)"
        echo
    fi
}

# ── Numbered plugin menu helper ──────────────────────────────
# usage: plugin_menu <title> <desc> <cmd1> <label1> <cmd2> <label2> ...
plugin_menu() {
    local title=$1 desc=$2
    shift 2
    echo
    _bright "  ▐▌ $title"
    _dim   "  ▐▌ $desc"
    echo
    local i=1
    local -a cmds labels
    while [[ $# -gt 0 ]]; do
        cmds+=("$1")
        labels+=("$2")
        echo -e "  ${c_dim}[$i]${c_none} ${c_bright}$2${c_none}"
        ((i++))
        shift 2
    done
    echo -e "  ${c_dim}[$i]${c_none} ${c_dim}back${c_none}"
    echo -ne " ${c_bright}>${c_none} "
    read -r REPLY
    if [[ $REPLY =~ ^[0-9]+$ && $REPLY -ge 1 && $REPLY -le ${#cmds[@]} ]]; then
        REPLY="${cmds[$((REPLY-1))]}"
    else
        REPLY=
    fi
}

plugin_list() {
    echo
    _bright "  ▐▌ plugins"
    _dim   "  ▐▌ installed extensions"
    echo

    local found=0
    if [[ -d "$PLUGIN_DIR" ]]; then
        for d in "$PLUGIN_DIR"/*/; do
            [[ -f "$d/plugin.sh" ]] || continue
            found=1
            (
                . "$d/plugin.sh"
                printf "  ${c_bright}%-16s${c_none} ${c_dim}v%s${c_none}\n" \
                    "$(plugin_info | cut -d'|' -f1)" \
                    "$(plugin_info | cut -d'|' -f2)"
                printf "  ${c_dim}%-16s${c_none}\n" "$(plugin_info | cut -d'|' -f3)"
                echo
            )
        done
    fi
    [[ $found -eq 0 ]] && _dim "  no plugins installed"
    echo
}

plugin_install() {
    local url=$1
    [[ ! $url ]] && {
        echo -e " ${c_dim}usage: sbx plugin install <git-url>${c_none}"
        echo -e " ${c_dim}or manually place in: $PLUGIN_DIR/<name>/plugin.sh${c_none}"
        return
    }
    warn "plugin install from git not yet implemented"
    echo -e " ${c_dim}manually place plugins in: $PLUGIN_DIR/<name>/plugin.sh${c_none}"
}

plugin_remove() {
    local name=$1
    [[ ! $name ]] && { echo -e " ${c_dim}usage: sbx plugin remove <name>${c_none}"; return; }
    # 安全：拒絕路徑穿越（.. / 絕對路徑 / 分隔符）
    [[ ! $name =~ ^[a-zA-Z0-9_\-]+$ ]] && { warn "plugin name 含不允許的字符（僅字母數字 _-）"; return; }
    [[ ! -d "$PLUGIN_DIR/$name" ]] && { warn "plugin '$name' not found"; return; }

    echo -ne " ${c_red}remove plugin '$name'? [y/N]:${c_none} "
    read -r confirm
    [[ "${confirm,,}" != "y" ]] && { _dim ">> cancelled"; return; }

    rm -rf "$PLUGIN_DIR/$name"
    _bright ">> plugin removed: $name"
}

# Load all plugins at startup
plugin_load_all() {
    if [[ -d "$PLUGIN_DIR" ]]; then
        for d in "$PLUGIN_DIR"/*/; do
            [[ -f "$d/plugin.sh" ]] && . "$d/plugin.sh" && plugin_init 2>/dev/null
        done
    fi
}
