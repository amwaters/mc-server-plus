#!/bin/bash
HELP="Cron job to back up the world data."
REQUIREMENTS=""

INPUT="/app/minecraft"
OUTPUT="/app/backups"


set -e


function send_rcon {
    rcon -H mc-server -p 25575 -P "${RCON_PASSWORD}" --minecraft "$@"
}

function notify_all_quiet {
    echo "$*" >&2
    send_rcon tellraw @a "{\"text\":\"$*\",\"italic\":true,\"color\":\"gray\"}" >&2 || true
}

function backup_if_modified {
    _NAME="$1"
    _F_IN="$INPUT/$_NAME"
    _NEW_CRC=`cksum "$_F_IN"`

    _CRC_FILE="$OUTPUT/$_NAME.crc"
    _OLD_CRC="NONE"
    if [ -f "$_CRC_FILE" ]; then
        _OLD_CRC=`cat "$_CRC_FILE"`
    fi
    if [ "$_NEW_CRC" == "$_OLD_CRC" ]; then
        return
    fi
    
    mkdir -p `dirname "$_CRC_FILE"`
    echo "$_NEW_CRC" > "$_CRC_FILE"
    
    _TS=`date -r "$_F_IN" "+%Y%m%d.%H%M%S"`
    _F_OUT="$OUTPUT/${_NAME}.${_TS}.gz"

    mkdir -p `dirname "$_F_OUT"`
    echo "Backing up $_F_IN" >&2
    cat "$_F_IN" | gzip -9 > "$_F_OUT"

    export _FILE_COUNT="$(( $_FILE_COUNT + 1 ))"
    export _TOTAL_SIZE="$(( $_TOTAL_SIZE + $(wc -c "$_F_IN" | cut -d ' ' -f1) ))"
    export _COMP_SIZE="$(( $_COMP_SIZE + $(wc -c "$_F_OUT" | cut -d ' ' -f1) ))"
}


function main {
    (
        _START=`date +%s`
        cd $INPUT
        notify_all_quiet "World backup started"
        send_rcon save-off
        send_rcon save-all

        _FILE_COUNT=0
        _TOTAL_SIZE=0
        _COMP_SIZE=0

        for FILE in `find * -type f`; do
            backup_if_modified "$FILE"
        done

        send_rcon save-on

        if (( $_FILE_COUNT > 0 )); then
            _SIZE="$(( $_TOTAL_SIZE / 1024 / 1024 ))"
            _COMP="$(( 100 - ( $_COMP_SIZE * 100 / $_TOTAL_SIZE ) ))"
            _DURATION="$(( $(date +%s) - $_START ))"
            notify_all_quiet "World backup complete, $_FILE_COUNT files, ${_SIZE}MB @ ${_COMP}% in ${_DURATION}s"
        else
            notify_all_quiet "World backup complete (nothing new to back up)"
        fi
    )
}


if [ "$1" == "--setup" ]; then
    echo -n "$REQUIREMENTS" | xargs apt-get install -y
elif [ "$1" == "--help" ]; then
    echo "$HELP"
elif [ "$0" == "$BASH_SOURCE" ]; then
    main "$@"
fi
