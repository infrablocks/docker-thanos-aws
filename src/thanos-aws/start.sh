#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

tracing_config_option=()
if [ -n "${THANOS_TRACING_CONFIGURATION}" ]; then
  tracing_config="${THANOS_TRACING_CONFIGURATION}"
  tracing_config_option+=("--tracing.config" "${tracing_config}")
fi

tracing_config_file_option=
if [ -n "${THANOS_TRACING_CONFIGURATION_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/tracing.yml
  echo "Fetching tracing configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_TRACING_CONFIGURATION_FILE_OBJECT_PATH}" \
    "${default_path}"
  tracing_config_file_option="--tracing.config-file=${default_path}"
fi
if [ -n "${THANOS_TRACING_CONFIGURATION_FILE_PATH}" ]; then
  file_path="${THANOS_TRACING_CONFIGURATION_FILE_PATH}"
  tracing_config_file_option="--tracing.config-file=${file_path}"
fi

log_level="${THANOS_LOG_LEVEL:-info}"
log_format="${THANOS_LOG_FORMAT:-json}"

echo "Running thanos."
# shellcheck disable=SC2086
exec su-exec thanos:thanos /opt/thanos/bin/thanos \
    --log.level="${log_level}" \
    --log.format="${log_format}" \
    \
    "${tracing_config_option[@]}" \
    ${tracing_config_file_option} \
    \
    "$@"
