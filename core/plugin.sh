# plugin.sh — sbx plugin system
#   sbx plugin list          list installed plugins
#   sbx plugin install <url> install a plugin
#   sbx plugin remove <name> remove a plugin

plugin_main() {
    case ${1,,} in
        list|ls|"") plugin_list ;;
        install|add) plugin_install "$2" ;;
        remove|delete|rm|del) plugin_remove "$2" ;;
        *) plugin_info_single "$1" ;;
    esac
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
                printf "  ${c_bright}%-16s${c_none} ${c_dim}v%s${c_none}  ${c_dim}%s${c_none}\n" \
                    "$(plugin_info | cut -d'|' -f1)" \
                    "$(plugin_info | cut -d'|' -f2)" \
                    "$(plugin_info | cut -d'|' -f3)"
            )
        done
    fi
    [[ $found -eq 0 ]] && _dim "  no plugins installed"
    echo
}

plugin_info_single() {
    local name=$1
    local plugin_file="$PLUGIN_DIR/$name/plugin.sh"
    [[ -f "$plugin_file" ]] || err "plugin '$name' not found"

    echo
    . "$plugin_file"
    printf "  ${c_bright}name:${c_none}        %s\n" "$(plugin_info | cut -d'|' -f1)"
    printf "  ${c_dim}version:${c_none}     %s\n" "$(plugin_info | cut -d'|' -f2)"
    printf "  ${c_dim}description:${c_none} %s\n" "$(plugin_info | cut -d'|' -f3)"
    echo
}

plugin_install() {
    local url=$1
    [[ ! $url ]] && err "usage: sbx plugin install <git-url>"
    warn "plugin install from git not yet implemented"
    echo -e " ${c_dim}manually place plugins in: $PLUGIN_DIR/<name>/plugin.sh${c_none}"
}

plugin_remove() {
    local name=$1
    [[ ! $name ]] && err "usage: sbx plugin remove <name>"
    [[ ! -d "$PLUGIN_DIR/$name" ]] && err "plugin '$name' not found"

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
