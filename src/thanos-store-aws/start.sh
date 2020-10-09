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

data_dir_option="--data-dir=/var/opt/thanos"

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
    ${data_dir_option} \
    \
    "${objstore_config_option[@]}" \
    ${objstore_config_file_option} \
    \
    ${web_external_prefix_option} \
    ${web_prefix_header_option} \
    \
    "$@"
