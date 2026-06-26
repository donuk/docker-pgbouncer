#!/bin/sh
set -e

# Pass all arguments along to the original entrypoint, but force the command to /fixconfig-and-run.sh
exec /entrypoint.sh /fixconfig-and-run.sh "$@"
