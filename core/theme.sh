# theme.sh — sbx theme engine
#   sbx theme              show current theme
#   sbx theme list         list available themes
#   sbx theme <name>       switch to theme

theme_list() {
    _dim ">> available themes"
    for f in "$THEME_DIR"/*.sh; do
        [[ -f "$f" ]] || continue
        local name=$(basename "$f" .sh)
        local marker=" "
        [[ "$name" == "$is_theme" ]] && marker="*"
        echo -e " ${c_bright}$marker${c_none} ${c_dim}$name${c_none}"
    done
}

theme_set() {
    local name=${1,,}

    if [[ ! $name || $name == "list" ]]; then
        theme_list
        [[ ! $name ]] && echo -e "\n ${c_dim}usage:${c_none} sbx theme <name>\n ${c_dim}current:${c_none} ${c_bright}$is_theme${c_none}"
        return
    fi

    local theme_file="$THEME_DIR/${name}.sh"
    [[ -f "$theme_file" ]] || {
        warn "theme '$name' not found"
        echo -ne " ${c_dim}available:${c_none}"
        for f in "$THEME_DIR"/*.sh; do
            [[ -f "$f" ]] && echo -ne " ${c_dim}$(basename "$f" .sh)${c_none}"
        done
        echo
        return
    }

    echo "$name" > "$is_core_dir/theme"
    . "$theme_file"
    is_theme="$name"
    _bright ">> theme: $name"
    echo -e " ${c_dim}restart sbx to apply fully${c_none}"
}
