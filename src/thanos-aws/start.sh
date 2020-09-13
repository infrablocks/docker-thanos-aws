#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running thanos."
exec su-exec thanos:thanos /opt/thanos/bin/thanos