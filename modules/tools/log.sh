# log.sh — log management
is_log_level_list=(
    trace
    debug
    info
    warn
    error
    fatal
    panic
    none
    del
)
log_set() {
    if [[ $1 ]]; then
        for v in ${is_log_level_list[@]}; do
            [[ $(grep -E -i "^${1,,}$" <<<$v) ]] && is_log_level_use=$v && break
        done
        [[ ! $is_log_level_use ]] && {
            err "unknown log level: $@\nusage: $is_sh_name log [${is_log_level_list[@]}]"
        }
        case $is_log_level_use in
        del)
            rm -rf $is_log_dir/*.log*
            msg "  $(_bright "log files deleted")"
            ;;
        none)
            rm -rf $is_log_dir/*.log*
            jq --arg dir "$is_log_dir" '.log={disabled:true}' "$is_config_json" >"$is_config_json.tmp" \
                && mv "$is_config_json.tmp" "$is_config_json"
            ;;
        *)
            jq --arg dir "$is_log_dir" --arg level "$is_log_level_use" \
                '.log={output:($dir + "/access.log"), level:$level, timestamp:true}' \
                "$is_config_json" >"$is_config_json.tmp" \
                && mv "$is_config_json.tmp" "$is_config_json"
            ;;
        esac

        manage restart &
        [[ $1 != 'del' ]] && msg "  $(_bright "$is_log_level_use")"
    else
        if [[ -f $is_log_dir/access.log ]]; then
            msg "  $(_bright "Ctrl-C to exit")"
            tail -f $is_log_dir/access.log
        else
            err "log file not found"
        fi
    fi
}
