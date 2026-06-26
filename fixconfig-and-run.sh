#!/bin/sh
set -e

PGBOUNCER_INI="/etc/pgbouncer/pgbouncer.ini"

# Use environment variables, or default values if unset
LISTEN_ADDR="${LISTEN_ADDR:-0.0.0.0}"
LISTEN_PORT="${LISTEN_PORT:-6432}"

tmpfile=$(mktemp)
inserted=0
while IFS= read -r line; do
    # Remove any existing listen_addr or listen_port directives
    if echo "$line" | grep -Eq '^[[:space:]]*listen_addr[[:space:]]*=' || echo "$line" | grep -Eq '^[[:space:]]*listen_port[[:space:]]*='; then
        continue
    fi
    echo "$line" >> "$tmpfile"
    if [ "$inserted" -eq 0 ] && echo "$line" | grep -q '^\[pgbouncer\]'; then
        echo "listen_addr = $LISTEN_ADDR" >> "$tmpfile"
        echo "listen_port = $LISTEN_PORT" >> "$tmpfile"
        inserted=1
    fi
done < "$PGBOUNCER_INI"

mv "$tmpfile" "$PGBOUNCER_INI"
chown pgbouncer:pgbouncer "$PGBOUNCER_INI"

cat /etc/pgbouncer/pgbouncer.ini | sed '/^\s*$/ d; /^\s*;/ d;'
echo "Running $@"
# Now run the original command (pass all arguments through)
exec "$@"
