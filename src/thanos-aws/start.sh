#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

log_level="${THANOS_LOG_LEVEL:-info}"
log_format="${THANOS_LOG_FORMAT:-json}"

echo "Running thanos."
exec su-exec thanos:thanos /opt/thanos/bin/thanos \
    --log.level="${log_level}" \
    --log.format="${log_format}" \
    "$@"
