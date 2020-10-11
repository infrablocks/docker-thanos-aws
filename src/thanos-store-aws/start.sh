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

data_dir="${THANOS_DATA_DIRECTORY:-/var/opt/thanos}"

chunk_pool_size="${THANOS_CHUNK_POOL_SIZE:-2GB}"
sync_block_duration="${THANOS_SYNC_BLOCK_DURATION:-3m}"
block_sync_concurrency="${THANOS_BLOCK_SYNC_CONCURRENCY:-20}"
consistency_delay="${THANOS_CONSISTENCY_DELAY:-0s}"
ignore_deletion_marks_delay="${THANOS_IGNORE_DELETION_MARKS_DELAY:-24h}"

index_cache_size_option=
if [ -n "${THANOS_INDEX_CACHE_SIZE}" ]; then
  index_cache_size_option="--index-cache-size=${THANOS_INDEX_CACHE_SIZE}"
fi

index_cache_config_option=()
if [ -n "${THANOS_INDEX_CACHE_CONFIGURATION}" ]; then
  index_cache_config="${THANOS_INDEX_CACHE_CONFIGURATION}"
  index_cache_config_option+=("--index-cache.config" "${index_cache_config}")
fi

index_cache_config_file_option=
if [ -n "${THANOS_INDEX_CACHE_CONFIGURATION_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/index-cache.yml
  echo "Fetching index cache configuration file."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_INDEX_CACHE_CONFIGURATION_FILE_OBJECT_PATH}" \
    "${default_path}"
  index_cache_config_file_option="--index-cache.config-file=${default_path}"
fi
if [ -n "${THANOS_INDEX_CACHE_CONFIGURATION_FILE_PATH}" ]; then
  file_path="${THANOS_INDEX_CACHE_CONFIGURATION_FILE_PATH}"
  index_cache_config_file_option="--index-cache.config-file=${file_path}"
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

web_external_prefix_option=
if [ -n "${THANOS_WEB_EXTERNAL_PREFIX}" ]; then
  web_external_prefix_option="--web.external-prefix=${THANOS_WEB_EXTERNAL_PREFIX}"
fi

web_prefix_header_option=
if [ -n "${THANOS_WEB_PREFIX_HEADER}" ]; then
  web_prefix_header_option="--web.prefix-header=${THANOS_WEB_PREFIX_HEADER}"
fi


# shellcheck disable=SC2086
exec /opt/thanos/bin/start.sh store \
    --http-address="${http_address}" \
    --http-grace-period="${http_grace_period}" \
    \
    --grpc-address="${grpc_address}" \
    --grpc-grace-period="${grpc_grace_period}" \
    \
    ${grpc_server_tls_cert_option} \
    ${grpc_server_tls_key_option} \
    ${grpc_server_tls_client_ca_option} \
    \
    --data-dir="${data_dir}" \
    --chunk-pool-size="${chunk_pool_size}" \
    --sync-block-duration="${sync_block_duration}" \
    --block-sync-concurrency="${block_sync_concurrency}" \
    --consistency-delay="${consistency_delay}" \
    --ignore-deletion-marks-delay="${ignore_deletion_marks_delay}" \
    \
    ${index_cache_size_option} \
    "${index_cache_config_option[@]}" \
    ${index_cache_config_file_option} \
    \
    "${objstore_config_option[@]}" \
    ${objstore_config_file_option} \
    \
    ${web_external_prefix_option} \
    ${web_prefix_header_option} \
    \
    "$@"
