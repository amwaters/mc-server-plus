#!/bin/bash
HELP="Entrypoint for single-cron-job containers.
cron-entrypoint.sh <Minute Hour DayOfMonth Month DayOfWeek> <Command>
Example: ./cron-entrypoint.sh '* * * * *' 'echo \"Hello World!\"'
"
REQUIREMENTS="cron"

set -e

function main {
    echo "Starting cron job"
    echo "$1" "root bash -c \"$2\" > /tmp/stdout 2> /tmp/stderr" > /etc/crontab

    if [ ! -p /tmp/stdout ]; then
        mkfifo /tmp/stdout /tmp/stderr
        chmod 0666 /tmp/stdout /tmp/stderr
    fi
    tail -f /tmp/stdout &
    tail -f /tmp/stderr >&2 &
    cron -f -L ${CRON_LOG_LEVEL:-15}
}

if [ "$1" == "--setup" ]; then
    echo -n "$REQUIREMENTS" | xargs apt-get install -y
    mkdir -p /tmp
elif [ "$1" == "--help" ]; then
    echo "$HELP"
elif [ "$0" == "$BASH_SOURCE" ]; then
    main "$@"
fi
