#!/bin/sh
set -e

PGBOUNCER_INI="/etc/pgbouncer/pgbouncer.ini"

overrides=$(mktemp)
tmpfile=$(mktemp)

# Collect settings as "option=value" lines; when an option appears twice the
# later line wins. LISTEN_ADDR / LISTEN_PORT are the legacy names (with
# defaults), PGBOUNCER_<OPTION> maps to the [pgbouncer] option of the same name.
echo "listen_addr=${LISTEN_ADDR:-0.0.0.0}" > "$overrides"
echo "listen_port=${LISTEN_PORT:-6432}" >> "$overrides"

env | while IFS= read -r entry; do
    name="${entry%%=*}"
    value="${entry#*=}"
    case "$name" in
        # Injected by Kubernetes for a Service called "pgbouncer"; not options
        PGBOUNCER_PORT | PGBOUNCER_PORT_* | PGBOUNCER_SERVICE_HOST | PGBOUNCER_SERVICE_PORT | PGBOUNCER_SERVICE_PORT_*)
            continue
            ;;
        PGBOUNCER_?*)
            option=$(printf '%s' "${name#PGBOUNCER_}" | tr 'A-Z' 'a-z')
            case "$option" in
                *[!a-z0-9_]*) continue ;;
            esac
            echo "$option=$value" >> "$overrides"
            ;;
    esac
done

# Drop any existing definition of an overridden option from [pgbouncer] and
# write the new values straight after the section header (adding the section
# if the file has none). Other sections are left untouched.
awk -v overrides="$overrides" '
function emit(   i) {
    for (i = 1; i <= n; i++) print order[i] " = " value[order[i]]
}
BEGIN {
    while ((getline line < overrides) > 0) {
        i = index(line, "=")
        key = substr(line, 1, i - 1)
        if (!(key in value)) order[++n] = key
        value[key] = substr(line, i + 1)
    }
    close(overrides)
}
/^[ \t]*\[.*\][ \t]*$/ {
    section = $0
    gsub(/[ \t\[\]]/, "", section)
    in_pgbouncer = (tolower(section) == "pgbouncer")
    print
    if (in_pgbouncer && !done) {
        emit()
        done = 1
    }
    next
}
in_pgbouncer && match($0, /^[ \t]*[A-Za-z0-9_.]+[ \t]*=/) {
    key = substr($0, 1, RLENGTH - 1)
    gsub(/[ \t]/, "", key)
    if (tolower(key) in value) next
}
{ print }
END {
    if (!done) {
        print "[pgbouncer]"
        emit()
    }
}
' "$PGBOUNCER_INI" > "$tmpfile"

rm -f "$overrides"
mv "$tmpfile" "$PGBOUNCER_INI"
chown pgbouncer:pgbouncer "$PGBOUNCER_INI"

cat /etc/pgbouncer/pgbouncer.ini | sed '/^\s*$/ d; /^\s*;/ d;'
echo "Running $@"
# Now run the original command (pass all arguments through)
exec "$@"
