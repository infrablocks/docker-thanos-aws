#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e
set -x

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

grpc_client_tls_secure_option=
if [[ "$THANOS_GRPC_CLIENT_TLS_SECURE_ENABLED" = "yes" ]]; then
  grpc_client_tls_secure_option="--grpc-client-tls-secure"
fi

grpc_client_tls_cert_option=
if [ -n "${THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/client-cert.pem
  echo "Fetching client TLS certificate."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_client_tls_cert_option="--grpc-client-tls-cert=${default_path}"
fi
if [ -n "${THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_PATH}"
  grpc_client_tls_cert_option="--grpc-client-tls-cert=${file_path}"
fi

grpc_client_tls_key_option=
if [ -n "${THANOS_GRPC_CLIENT_TLS_KEY_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/client-key.pem
  echo "Fetching client TLS key."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_CLIENT_TLS_KEY_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_client_tls_key_option="--grpc-client-tls-key=${default_path}"
fi
if [ -n "${THANOS_GRPC_CLIENT_TLS_KEY_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_CLIENT_TLS_KEY_FILE_PATH}"
  grpc_client_tls_key_option="--grpc-client-tls-key=${file_path}"
fi

grpc_client_tls_ca_option=
if [ -n "${THANOS_GRPC_CLIENT_TLS_CA_FILE_OBJECT_PATH}" ]; then
  default_path=/opt/thanos/conf/client-ca.pem
  echo "Fetching client TLS CA."
  fetch_file_from_s3 \
    "${AWS_S3_BUCKET_REGION}" \
    "${THANOS_GRPC_CLIENT_TLS_CA_FILE_OBJECT_PATH}" \
    "${default_path}"
  grpc_client_tls_ca_option="--grpc-client-tls-ca=${default_path}"
fi
if [ -n "${THANOS_GRPC_CLIENT_TLS_CA_FILE_PATH}" ]; then
  file_path="${THANOS_GRPC_CLIENT_TLS_CA_FILE_PATH}"
  grpc_client_tls_ca_option="--grpc-client-tls-ca=${file_path}"
fi

web_route_prefix_option=
if [ -n "${THANOS_WEB_ROUTE_PREFIX}" ]; then
  web_route_prefix_option="--web.route-prefix=${THANOS_WEB_ROUTE_PREFIX}"
fi

web_external_prefix_option=
if [ -n "${THANOS_WEB_EXTERNAL_PREFIX}" ]; then
  web_external_prefix_option="--web.external-prefix=${THANOS_WEB_EXTERNAL_PREFIX}"
fi

web_prefix_header_option=
if [ -n "${THANOS_WEB_PREFIX_HEADER}" ]; then
  web_prefix_header_option="--web.prefix-header=${THANOS_WEB_PREFIX_HEADER}"
fi

log_request_decision_option=
if [ -n "${THANOS_LOG_REQUEST_DECISION}" ]; then
  decision="${THANOS_LOG_REQUEST_DECISION}"
  log_request_decision_option="--log.request.decision=${decision}"
fi

query_timeout_option=
if [ -n "${THANOS_QUERY_TIMEOUT}" ]; then
  query_timeout_option="--query.timeout=${THANOS_QUERY_TIMEOUT}"
fi

query_max_concurrent_option=
if [ -n "${THANOS_QUERY_MAX_CONCURRENT}" ]; then
  max_concurrent="${THANOS_QUERY_MAX_CONCURRENT}"
  query_max_concurrent_option="--query.max-concurrent=${max_concurrent}"
fi

query_lookback_delta_option=
if [ -n "${THANOS_QUERY_LOOKBACK_DELTA}" ]; then
  lookback_delta="${THANOS_QUERY_LOOKBACK_DELTA}"
  query_lookback_delta_option="--query.lookback-delta=${lookback_delta}"
fi

query_max_concurrent_select_option=
if [ -n "${THANOS_QUERY_MAX_CONCURRENT_SELECT}" ]; then
  select="${THANOS_QUERY_MAX_CONCURRENT_SELECT}"
  query_max_concurrent_select_option="--query.max-concurrent-select=${select}"
fi

query_replica_label_option=
if [ -n "${THANOS_QUERY_REPLICA_LABEL}" ]; then
  label="${THANOS_QUERY_REPLICA_LABEL}"
  query_replica_label_option="--query.replica-label=${label}"
fi

query_auto_downsampling_option=
if [[ "$THANOS_QUERY_AUTO_DOWNSAMPLING_ENABLED" = "yes" ]]; then
  query_auto_downsampling_option="--query.auto-downsampling"
fi

query_partial_response_option=
if [[ "$THANOS_QUERY_PARTIAL_RESPONSE_ENABLED" = "yes" ]]; then
  query_partial_response_option="--query.partial-response"
fi

query_default_evaluation_interval_option=
if [ -n "${THANOS_QUERY_DEFAULT_EVALUATION_INTERVAL}" ]; then
  option="--query.default-evaluation-interval"
  interval="${THANOS_QUERY_DEFAULT_EVALUATION_INTERVAL}"
  query_default_evaluation_interval_option="${option}=${interval}"
fi

store_address_options=()
for store_address in ${THANOS_STORE_ADDRESSES//,/ }; do
  store_address_options+=("--store=${store_address}")
done

store_strict_address_options=()
for store_strict_address in ${THANOS_STORE_STRICT_ADDRESSES//,/ }; do
  store_strict_address_options+=("--store-strict=${store_strict_address}")
done

store_sd_files_options=()
if [ -n "${THANOS_STORE_SD_FILE_OBJECT_PATHS}" ]; then
  sd_file_dir=/opt/thanos/conf/sd
  for sd_file_object_path in ${THANOS_STORE_SD_FILE_OBJECT_PATHS//,/ }; do
    sd_file_name="${sd_file_object_path##*/}"
    sd_file_path="${sd_file_dir}/${sd_file_name}"

    fetch_file_from_s3 \
      "${AWS_S3_BUCKET_REGION}" \
      "${sd_file_object_path}" \
      "${sd_file_path}"

    store_sd_files_options+=("--store.sd-files=${sd_file_path}")
  done
fi
if [ -n "${THANOS_STORE_SD_FILE_PATHS}" ]; then
  for sd_file_path in ${THANOS_STORE_SD_FILE_PATHS//,/ }; do
    store_sd_files_options+=("--store.sd-files=${sd_file_path}")
  done
fi

store_sd_interval_option=
if [ -n "${THANOS_STORE_SD_INTERVAL}" ]; then
  interval="${THANOS_STORE_SD_INTERVAL}"
  store_sd_interval_option="--store.sd-interval=${interval}"
fi

store_sd_dns_interval_option=
if [ -n "${THANOS_STORE_SD_DNS_INTERVAL}" ]; then
  interval="${THANOS_STORE_SD_DNS_INTERVAL}"
  store_sd_dns_interval_option="--store.sd-dns-interval=${interval}"
fi

store_unhealthy_timeout_option=
if [ -n "${THANOS_STORE_UNHEALTHY_TIMEOUT}" ]; then
  timeout="${THANOS_STORE_UNHEALTHY_TIMEOUT}"
  store_unhealthy_timeout_option="--store.unhealthy-timeout=${timeout}"
fi

store_response_timeout_option=
if [ -n "${THANOS_STORE_RESPONSE_TIMEOUT}" ]; then
  timeout="${THANOS_STORE_RESPONSE_TIMEOUT}"
  store_response_timeout_option="--store.response-timeout=${timeout}"
fi

selector_label_options=()
for selector_label in ${THANOS_SELECTOR_LABELS//,/ }; do
  # shellcheck disable=SC2206
  selector_label_parts=(${selector_label//=/ })
  selector_label_options+=("--selector-label=${selector_label_parts[0]}=\"${selector_label_parts[1]}\"")
done


# shellcheck disable=SC2086
exec /opt/thanos/bin/start.sh query \
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
    ${grpc_client_tls_secure_option} \
    ${grpc_client_tls_cert_option} \
    ${grpc_client_tls_key_option} \
    ${grpc_client_tls_ca_option} \
    \
    ${web_route_prefix_option} \
    ${web_external_prefix_option} \
    ${web_prefix_header_option} \
    \
    ${log_request_decision_option} \
    \
    ${query_timeout_option} \
    ${query_max_concurrent_option} \
    ${query_lookback_delta_option} \
    ${query_max_concurrent_select_option} \
    ${query_replica_label_option} \
    ${query_auto_downsampling_option} \
    ${query_partial_response_option} \
    ${query_default_evaluation_interval_option} \
    \
    "${store_address_options[@]}" \
    "${store_strict_address_options[@]}" \
    "${store_sd_files_options[@]}" \
    ${store_sd_interval_option} \
    ${store_sd_dns_interval_option} \
    ${store_unhealthy_timeout_option} \
    ${store_response_timeout_option} \
    \
    "${selector_label_options[@]}" \
    "$@"
