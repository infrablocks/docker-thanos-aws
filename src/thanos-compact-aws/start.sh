#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

wait_option="--wait"
if [[ "$THANOS_WAIT_ENABLED" = "no" ]]; then
  wait_option=
fi
wait_interval_option=
if [ -n "${THANOS_WAIT_INTERVAL}" ]; then
  wait_interval_option="--wait-interval=${THANOS_WAIT_INTERVAL}"
fi

http_address="${THANOS_HTTP_ADDRESS:-0.0.0.0:10902}"
http_grace_period="${THANOS_HTTP_GRACE_PERIOD:-2m}"

data_dir="${THANOS_DATA_DIRECTORY:-/var/opt/thanos}"

consistency_delay_option=
if [ -n "${THANOS_CONSISTENCY_DELAY}" ]; then
  consistency_delay_option="--consistency-delay=${THANOS_CONSISTENCY_DELAY}"
fi
delete_delay_option=
if [ -n "${THANOS_DELETE_DELAY}" ]; then
  delete_delay_option="--delete-delay=${THANOS_DELETE_DELAY}"
fi
bucket_web_label_option=
if [ -n "${THANOS_BUCKET_WEB_LABEL}" ]; then
  bucket_web_label_option="--bucket-web-label=${THANOS_BUCKET_WEB_LABEL}"
fi

objstore_config_option=()
if [ -n "${THANOS_OBJECT_STORE_CONFIGURATION}" ]; then
  objstore_config="${THANOS_OBJECT_STORE_CONFIGURATION}"
  objstore_config_option+=("--objstore.config" "${objstore_config}")
fi

objstore_config_file_option=
if [ -n "${THANOS_OBJECT_STORE_CONFIGURATION_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/objstore.yml
  echo "Fetching object store configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_OBJECT_STORE_CONFIGURATION_FILE_OBJECT_PATH}" \
    "${default_path}"
  objstore_config_file_option="--objstore.config-file=${default_path}"
fi
if [ -n "${THANOS_OBJECT_STORE_CONFIGURATION_FILE_PATH}" ]; then
  file_path="${THANOS_OBJECT_STORE_CONFIGURATION_FILE_PATH}"
  objstore_config_file_option="--objstore.config-file=${file_path}"
fi

retention_resolution_raw_option=
if [ -n "${THANOS_RETENTION_RESOLUTION_RAW}" ]; then
  retention_resolution_raw_option="--retention.resolution-raw=${THANOS_RETENTION_RESOLUTION_RAW}"
fi

retention_resolution_5m_option=
if [ -n "${THANOS_RETENTION_RESOLUTION_5M}" ]; then
  retention_resolution_5m_option="--retention.resolution-5m=${THANOS_RETENTION_RESOLUTION_5M}"
fi

retention_resolution_1h_option=
if [ -n "${THANOS_RETENTION_RESOLUTION_1H}" ]; then
  retention_resolution_1h_option="--retention.resolution-1h=${THANOS_RETENTION_RESOLUTION_1H}"
fi

downsampling_disable_option=
if [[ "$THANOS_DOWNSAMPLING_ENABLED" = "no" ]]; then
  downsampling_disable_option="--downsampling.disable"
fi

compact_concurrency_option=
if [ -n "${THANOS_COMPACT_CONCURRENCY}" ]; then
  compact_concurrency_option="--compact.concurrency=${THANOS_COMPACT_CONCURRENCY}"
fi

block_viewer_global_sync_block_interval_option=
if [ -n "${THANOS_BLOCK_VIEWER_GLOBAL_SYNC_BLOCK_INTERVAL}" ]; then
  block_viewer_global_sync_block_interval_option="--block-viewer.global.sync-block-interval=${THANOS_BLOCK_VIEWER_GLOBAL_SYNC_BLOCK_INTERVAL}"
fi

selector_relabel_config_option=()
if [ -n "${THANOS_SELECTOR_RELABEL_CONFIGURATION}" ]; then
  selector_relabel_config="${THANOS_SELECTOR_RELABEL_CONFIGURATION}"
  selector_relabel_config_option+=("--selector.relabel-config" "${selector_relabel_config}")
fi

selector_relabel_config_file_option=
if [ -n "${THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/selector-relabelling.yml
  echo "Fetching selector relabel configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_OBJECT_PATH}" \
    "${default_path}"
  selector_relabel_config_file_option="--selector.relabel-config-file=${default_path}"
fi
if [ -n "${THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_PATH}" ]; then
  file_path="${THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_PATH}"
  selector_relabel_config_file_option="--selector.relabel-config-file=${file_path}"
fi

web_external_prefix_option=
if [ -n "${THANOS_WEB_EXTERNAL_PREFIX}" ]; then
  web_external_prefix_option="--web.external-prefix=${THANOS_WEB_EXTERNAL_PREFIX}"
fi

web_prefix_header_option=
if [ -n "${THANOS_WEB_PREFIX_HEADER}" ]; then
  web_prefix_header_option="--web.prefix-header=${THANOS_WEB_PREFIX_HEADER}"
fi


# shellcheck disable=SC2086
exec /opt/thanos/bin/start.sh compact \
    \
    ${wait_option} \
    ${wait_interval_option} \
    \
    --http-address="${http_address}" \
    --http-grace-period="${http_grace_period}" \
    \
    --data-dir="${data_dir}" \
    ${consistency_delay_option} \
    ${delete_delay_option} \
    ${bucket_web_label_option} \
    \
    "${objstore_config_option[@]}" \
    ${objstore_config_file_option} \
    \
    ${retention_resolution_raw_option} \
    ${retention_resolution_5m_option} \
    ${retention_resolution_1h_option} \
    \
    ${downsampling_disable_option} \
    \
    ${block_viewer_global_sync_block_interval_option} \
    \
    ${compact_concurrency_option} \
    \
    "${selector_relabel_config_option[@]}" \
    ${selector_relabel_config_file_option} \
    \
    ${web_external_prefix_option} \
    ${web_prefix_header_option} \
    \
    "$@"
