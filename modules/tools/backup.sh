# backup.sh — 備份還原
#   sbx backup              建立備份
#   sbx backup list         列出備份
#   sbx restore <file>      還原備份

is_backup_dir=/root

backup_set() {
    case ${1,,} in
    list)
        backup_list
        ;;
    *)
        backup_create
        ;;
    esac
}

backup_create() {
    local ts=$(date +%Y%m%d-%H%M%S)
    local file="$is_backup_dir/sbx-backup-$ts.tar.gz"

    _dim ">> $L_BACKUP_CREATE"
    tar czf "$file" -C / "$(echo $is_core_dir | sed 's|^/||')" 2>/dev/null
    if [[ $? == 0 ]]; then
        local size=$(du -h "$file" | cut -f1)
        msg "  $(_bright "$(basename $file) ($size)")"
    else
        _dim "[-] $L_BACKUP_FAILED"
    fi
}

backup_list() {
    _dim ">> $L_BACKUP_LIST"
    local found=0
    for f in $(ls $is_backup_dir/sbx-backup-*.tar.gz 2>/dev/null | sort -r); do
        local size=$(du -h "$f" | cut -f1)
        msg "  $(_bright "$(basename $f)")  $size"
        found=1
    done
    [[ $found == 0 ]] && _dim "[-] $L_BACKUP_NO_FILES"
}

restore_set() {
    local file=$1
    [[ ! $file ]] && err "usage: sbx restore <backup-file>"
    [[ ! -f $file ]] && err "file not found: $file"

    _dim ">> $L_BACKUP_RESTORE"
    # backup current first
    backup_create
    # restore
    tar xzf "$file" -C / 2>/dev/null
    if [[ $? == 0 ]]; then
        msg "  $(_bright "$L_BACKUP_RESTART")"
        manage restart &
    else
        _dim "[-] $L_BACKUP_FAILED"
    fi
}
