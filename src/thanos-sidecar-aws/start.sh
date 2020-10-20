#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

http_address="${THANOS_HTTP_ADDRESS:-0.0.0.0:10902}"
http_grace_period="${THANOS_HTTP_GRACE_PERIOD:-2m}"

grpc_address="${THANOS_GRPC_ADDRESS:-0.0.0.0:10901}"
grpc_grace_period="${THANOS_GRPC_GRACE_PERIOD:-2m}"

grpc_server_tls_cert_option=
if [ -n "${THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/server-cert.pem
  echo "Fetching server TLS certificate."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_server_tls_cert_option="--grpc-server-tls-cert=${default_path}"
fi
if [ -n "${THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_PATH}"
  grpc_server_tls_cert_option="--grpc-server-tls-cert=${file_path}"
fi

grpc_server_tls_key_option=
if [ -n "${THANOS_GRPC_SERVER_TLS_KEY_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/server-key.pem
  echo "Fetching server TLS key."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_SERVER_TLS_KEY_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_server_tls_key_option="--grpc-server-tls-key=${default_path}"
fi
if [ -n "${THANOS_GRPC_SERVER_TLS_KEY_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_SERVER_TLS_KEY_FILE_PATH}"
  grpc_server_tls_key_option="--grpc-server-tls-key=${file_path}"
fi

grpc_server_tls_client_ca_option=
if [ -n "${THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/server-client-ca.pem
  echo "Fetching server TLS client CA."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_server_tls_client_ca_option="--grpc-server-tls-client-ca=${default_path}"
fi
if [ -n "${THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_PATH}"
  grpc_server_tls_client_ca_option="--grpc-server-tls-client-ca=${file_path}"
fi

prometheus_url="${THANOS_PROMETHEUS_URL:-http://localhost:9090}"
prometheus_ready_timeout="${THANOS_PROMETHEUS_READY_TIMEOUT:-10m}"

rcv_conn_pool_size="${THANOS_RECEIVE_CONNECTION_POOL_SIZE:-0}"
rcv_conn_pool_size_per_host=\
"${THANOS_RECEIVE_CONNECTION_POOL_SIZE_PER_HOST:-100}"

tsdb_path="${THANOS_TSDB_PATH:-/var/opt/prometheus}"

reloader_config_file="${THANOS_RELOADER_CONFIGURATION_FILE}"
reloader_config_envsubst_file="${THANOS_RELOADER_CONFIGURATION_ENVSUBST_FILE}"
reloader_watch_interval="${THANOS_RELOADER_WATCH_INTERVAL:-3m}"
reloader_retry_interval="${THANOS_RELOADER_RETRY_INTERVAL:-5s}"

reloader_rule_dir_options=()
if [ -n "${THANOS_RELOADER_RULE_DIRECTORIES}" ]; then
  for rule_dir in ${THANOS_RELOADER_RULE_DIRECTORIES//,/ }; do
    reloader_rule_dir_options+=("--reloader.rule-dir" "${rule_dir}")
  done
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

shipper_upload_compacted_option=
if [[ "$THANOS_SHIPPER_UPLOAD_COMPACTED_ENABLED" = "yes" ]]; then
  shipper_upload_compacted_option="--shipper.upload-compacted"
fi

min_time_option=
if [ -n "$THANOS_MINIMUM_TIME" ]; then
  min_time_option="--min-time=${THANOS_MINIMUM_TIME}"
fi

# shellcheck disable=SC2086
exec /opt/thanos/bin/start.sh sidecar \
    --http-address="${http_address}" \
    --http-grace-period="${http_grace_period}" \
    \
    --grpc-address="${grpc_address}" \
    --grpc-grace-period="${grpc_grace_period}" \
    ${grpc_server_tls_cert_option} \
    ${grpc_server_tls_key_option} \
    ${grpc_server_tls_client_ca_option} \
    \
    --prometheus.url="${prometheus_url}" \
    --prometheus.ready_timeout="${prometheus_ready_timeout}" \
    \
    --receive.connection-pool-size="${rcv_conn_pool_size}" \
    --receive.connection-pool-size-per-host="${rcv_conn_pool_size_per_host}" \
    \
    --tsdb.path="${tsdb_path}" \
    \
    --reloader.config-file="${reloader_config_file}" \
    --reloader.config-envsubst-file="${reloader_config_envsubst_file}" \
    --reloader.watch-interval="${reloader_watch_interval}" \
    --reloader.retry-interval="${reloader_retry_interval}" \
    "${reloader_rule_dir_options[@]}" \
    \
    "${objstore_config_option[@]}" \
    ${objstore_config_file_option} \
    \
    ${shipper_upload_compacted_option} \
    \
    ${min_time_option} \
    \
    "$@"
