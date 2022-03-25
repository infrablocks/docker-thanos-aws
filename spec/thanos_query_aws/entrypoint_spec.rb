# frozen_string_literal: true

require 'spec_helper'

describe 'thanos-query-aws entrypoint' do
  def metadata_service_url
    'http://metadata:1338'
  end

  def s3_endpoint_url
    'http://s3:4566'
  end

  def s3_bucket_region
    'us-east-1'
  end

  def s3_bucket_path
    's3://bucket'
  end

  def s3_env_file_object_path
    's3://bucket/env-file.env'
  end

  def environment
    {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => '...',
      'AWS_SECRET_ACCESS_KEY' => '...',
      'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
      'AWS_S3_BUCKET_REGION' => s3_bucket_region,
      'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
    }
  end

  def image
    'thanos-query-aws:latest'
  end

  def extra
    {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
        'NetworkMode' => 'docker_thanos_aws_test_default'
      }
    }
  end

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'runs thanos query' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
    end

    it 'runs thanos query subcommand' do
      expect(process('/opt/thanos/bin/thanos').args).to(match(/query/))
    end

    it 'listens on port 10902 on all interfaces for HTTP traffic' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--http-address=0.0.0.0:10902/))
    end

    it 'uses an HTTP grace period of 2 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--http-grace-period=2m/))
    end

    it 'listens on port 10901 on all interfaces for gRPC traffic' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--grpc-address=0.0.0.0:10901/))
    end

    it 'uses a gRPC grace period of 2 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--grpc-grace-period=2m/))
    end

    it 'does not set gRPC server TLS cert' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-cert/))
    end

    it 'does not set gRPC server TLS key' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-key/))
    end

    it 'does not set gRPC server TLS client CA' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-client-ca/))
    end

    it 'does not set gRPC client TLS secure' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-client-tls-secure/))
    end

    it 'does not set gRPC client TLS cert' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-client-tls-cert/))
    end

    it 'does not set gRPC client TLS key' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-client-tls-key/))
    end

    it 'does not set gRPC client TLS CA' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-client-tls-ca/))
    end

    it 'does not set gRPC client TLS server name' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-client-server-name/))
    end

    it 'does not include web external prefix configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--web\.external-prefix/))
    end

    it 'does not include web route prefix configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--web\.route-prefix/))
    end

    it 'does not include web prefix header configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--web\.prefix-header/))
    end

    it 'does not include log configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--log\.request.decision/))
    end

    it 'does not include query timeout configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.timeout/))
    end

    it 'does not include query max concurrent configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.max-concurrent/))
    end

    it 'does not include query lookback delta configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.lookback-delta/))
    end

    it 'does not include query max concurrent select configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.max-concurrent-select/))
    end

    it 'does not include query replica label configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.replica-label/))
    end

    it 'does not include query auto downsampling configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.auto-downsampling/))
    end

    it 'does not include query partial response configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.partial-response/))
    end

    it 'does not include query default evaluation interval configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--query\.default-evaluation-interval/))
    end

    it 'does not include any store configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store=/))
    end

    it 'does not include any store strict configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store-strict=/))
    end

    it 'does not include any store sd files configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store\.sd-files/))
    end

    it 'does not include any store sd interval configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store\.sd-interval/))
    end

    it 'does not include any store sd dns interval configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store\.sd-dns-interval/))
    end

    it 'does not include any store unhealthy timeout configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store\.unhealthy-timeout/))
    end

    it 'does not include any store response timeout configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--store\.response-timeout/))
    end

    it 'does not include any selector labels' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--selector-label/))
    end
  end

  describe 'with HTTP configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_HTTP_ADDRESS' => '0.0.0.0:11902',
          'THANOS_HTTP_GRACE_PERIOD' => '4m'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided HTTP address' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--http-address=0.0.0.0:11902/))
    end

    it 'uses the provided HTTP grace period' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--http-grace-period=4m/))
    end
  end

  describe 'with gRPC configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_GRPC_ADDRESS' => '0.0.0.0:11901',
          'THANOS_GRPC_GRACE_PERIOD' => '4m'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided gRPC address' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--grpc-address=0.0.0.0:11901/))
    end

    it 'uses the provided gRPC grace period' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--grpc-grace-period=4m/))
    end
  end

  describe 'with gRPC server TLS configuration' do
    context 'when passed filesystem paths for TLS files' do
      before(:all) do
        cert = File.read('spec/fixtures/example-cert.pem')
        key = File.read('spec/fixtures/example-key.pem')
        client_ca = File.read('spec/fixtures/example-ca.pem')

        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_PATH' => '/cert.pem',
            'THANOS_GRPC_SERVER_TLS_KEY_FILE_PATH' => '/key.pem',
            'THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_PATH' => '/client-ca.pem'
          }
        )

        execute_command("echo \"#{cert}\" > /cert.pem")
        execute_command("echo \"#{key}\" > /key.pem")
        execute_command("echo \"#{client_ca}\" > /client-ca.pem")
        execute_command('chown thanos:thanos /cert.pem')
        execute_command('chown thanos:thanos /key.pem')
        execute_command('chown thanos:thanos /client-ca.pem')

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided file path as the server TLS cert' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-server-tls-cert=/cert.pem}
              ))
      end

      it 'uses the provided file path as the server TLS key' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-server-tls-key=/key.pem}
              ))
      end

      it 'uses the provided file path as the server TLS client CA' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-server-tls-client-ca=/client-ca.pem}
              ))
      end
    end

    context 'when passed object paths for TLS files' do
      def cert
        File.read('spec/fixtures/example-cert.pem')
      end

      def key
        File.read('spec/fixtures/example-key.pem')
      end

      def client_ca
        File.read('spec/fixtures/example-ca.pem')
      end

      def create_bucket_object(content, path)
        create_object(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: path,
          content:
        )
      end

      before(:all) do
        cert_object_path = "#{s3_bucket_path}/cert.pem"
        key_object_path = "#{s3_bucket_path}/key.pem"
        client_ca_object_path = "#{s3_bucket_path}/client-ca.pem"

        create_bucket_object(cert, cert_object_path)
        create_bucket_object(key, key_object_path)
        create_bucket_object(client_ca, client_ca_object_path)

        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_SERVER_TLS_CERTIFICATE_FILE_OBJECT_PATH' =>
              cert_object_path,
            'THANOS_GRPC_SERVER_TLS_KEY_FILE_OBJECT_PATH' =>
              key_object_path,
            'THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_OBJECT_PATH' =>
              client_ca_object_path
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specified server TLS certificate, key and client CA' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing)
          .to(eq("server-cert.pem\nserver-client-ca.pem\nserver-key.pem\n"))
      end

      it 'uses the correct server TLS certificate contents' do
        cert_path = '/opt/thanos/conf/server-cert.pem'
        cert_contents = command("cat #{cert_path}").stdout

        expect(cert_contents).to(eq(cert))
      end

      it 'uses the correct server TLS key contents' do
        key_path = '/opt/thanos/conf/server-key.pem'
        key_contents = command("cat #{key_path}").stdout

        expect(key_contents).to(eq(key))
      end

      it 'uses the correct server TLS client CA contents' do
        client_ca_path = '/opt/thanos/conf/server-client-ca.pem'
        client_ca_contents = command("cat #{client_ca_path}").stdout

        expect(client_ca_contents).to(eq(client_ca))
      end

      it 'uses the fetched TLS certificate' do
        cert_path = '/opt/thanos/conf/server-cert.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-server-tls-cert=#{Regexp.escape(cert_path)}/
              ))
      end

      it 'uses the fetched TLS key' do
        key_path = '/opt/thanos/conf/server-key.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-server-tls-key=#{Regexp.escape(key_path)}/
              ))
      end

      it 'uses the fetched TLS client CA' do
        client_ca_path = '/opt/thanos/conf/server-client-ca.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-server-tls-client-ca=#{Regexp.escape(client_ca_path)}/
              ))
      end
    end
  end

  describe 'with gRPC client TLS configuration' do
    context 'when disabled' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_CLIENT_TLS_SECURE_ENABLED' => 'no'
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'disables client TLS' do
        expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(
                    /--grpc-client-tls-secure/
                  ))
      end
    end

    context 'with client server name' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_CLIENT_SERVER_NAME' => 'thanos.example.com'
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided server name' do
        expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(
                    /--grpc-client-server-name=thanos.example.com/
                  ))
      end
    end

    context 'when passed filesystem paths for TLS files' do
      before(:all) do
        cert = File.read('spec/fixtures/example-cert.pem')
        key = File.read('spec/fixtures/example-key.pem')
        ca = File.read('spec/fixtures/example-ca.pem')

        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_CLIENT_TLS_SECURE_ENABLED' => 'yes',
            'THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_PATH' => '/cert.pem',
            'THANOS_GRPC_CLIENT_TLS_KEY_FILE_PATH' => '/key.pem',
            'THANOS_GRPC_CLIENT_TLS_CA_FILE_PATH' => '/ca.pem'
          }
        )

        execute_command("echo \"#{cert}\" > /cert.pem")
        execute_command("echo \"#{key}\" > /key.pem")
        execute_command("echo \"#{ca}\" > /ca.pem")
        execute_command('chown thanos:thanos /cert.pem')
        execute_command('chown thanos:thanos /key.pem')
        execute_command('chown thanos:thanos /ca.pem')

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'enables client TLS' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-client-tls-secure/
              ))
      end

      it 'uses the provided file path as the server TLS cert' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-client-tls-cert=/cert.pem}
              ))
      end

      it 'uses the provided file path as the client TLS key' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-client-tls-key=/key.pem}
              ))
      end

      it 'uses the provided file path as the client TLS client CA' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                %r{--grpc-client-tls-ca=/ca.pem}
              ))
      end
    end

    context 'when passed object paths for TLS files' do
      def cert
        File.read('spec/fixtures/example-cert.pem')
      end

      def key
        File.read('spec/fixtures/example-key.pem')
      end

      def ca
        File.read('spec/fixtures/example-ca.pem')
      end

      def create_bucket_object(content, path)
        create_object(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: path,
          content:
        )
      end

      before(:all) do
        cert_object_path = "#{s3_bucket_path}/cert.pem"
        key_object_path = "#{s3_bucket_path}/key.pem"
        ca_object_path = "#{s3_bucket_path}/ca.pem"

        create_bucket_object(cert, cert_object_path)
        create_bucket_object(key, key_object_path)
        create_bucket_object(ca, ca_object_path)

        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_GRPC_CLIENT_TLS_SECURE_ENABLED' => 'yes',
            'THANOS_GRPC_CLIENT_TLS_CERTIFICATE_FILE_OBJECT_PATH' =>
              cert_object_path,
            'THANOS_GRPC_CLIENT_TLS_KEY_FILE_OBJECT_PATH' =>
              key_object_path,
            'THANOS_GRPC_CLIENT_TLS_CA_FILE_OBJECT_PATH' =>
              ca_object_path
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'enables client TLS' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-client-tls-secure/
              ))
      end

      it 'fetches the specified server TLS certificate, key and client CA' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing)
          .to(eq("client-ca.pem\nclient-cert.pem\nclient-key.pem\n"))
      end

      it 'uses the correct server TLS certificate contents' do
        cert_path = '/opt/thanos/conf/client-cert.pem'
        cert_contents = command("cat #{cert_path}").stdout

        expect(cert_contents).to(eq(cert))
      end

      it 'uses the correct server TLS key contents' do
        key_path = '/opt/thanos/conf/client-key.pem'
        key_contents = command("cat #{key_path}").stdout

        expect(key_contents).to(eq(key))
      end

      it 'uses the correct server TLS client CA' do
        ca_path = '/opt/thanos/conf/client-ca.pem'
        ca_contents = command("cat #{ca_path}").stdout

        expect(ca_contents).to(eq(ca))
      end

      it 'uses the fetched TLS certificate' do
        cert_path = '/opt/thanos/conf/client-cert.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-client-tls-cert=#{Regexp.escape(cert_path)}/
              ))
      end

      it 'uses the fetched TLS key' do
        key_path = '/opt/thanos/conf/client-key.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-client-tls-key=#{Regexp.escape(key_path)}/
              ))
      end

      it 'uses the fetched TLS client CA' do
        ca_path = '/opt/thanos/conf/client-ca.pem'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--grpc-client-tls-ca=#{Regexp.escape(ca_path)}/
              ))
      end
    end
  end

  describe 'with web configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_WEB_ROUTE_PREFIX' => '/thanos',
          'THANOS_WEB_EXTERNAL_PREFIX' => '/query',
          'THANOS_WEB_PREFIX_HEADER' => 'X-Forwarded-Prefix'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided web route prefix' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              %r{--web\.route-prefix=/thanos}
            ))
    end

    it 'uses the provided web external prefix' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              %r{--web\.external-prefix=/query}
            ))
    end

    it 'uses the provided web prefix header' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              /--web\.prefix-header=X-Forwarded-Prefix/
            ))
    end
  end

  describe 'with log configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_LOG_REQUEST_DECISION' => 'NoLogCall'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided log request decision' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              /--log\.request\.decision=NoLogCall/
            ))
    end
  end

  describe 'with query configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_QUERY_TIMEOUT' => '3m',
          'THANOS_QUERY_MAX_CONCURRENT' => '30',
          'THANOS_QUERY_LOOKBACK_DELTA' => '10m',
          'THANOS_QUERY_MAX_CONCURRENT_SELECT' => '8',
          'THANOS_QUERY_REPLICA_LABELS' => 'instance,region',
          'THANOS_QUERY_AUTO_DOWNSAMPLING_ENABLED' => 'yes',
          'THANOS_QUERY_PARTIAL_RESPONSE_ENABLED' => 'yes',
          'THANOS_QUERY_DEFAULT_EVALUATION_INTERVAL' => '2m'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided query timeout' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.timeout=3m/))
    end

    it 'uses the provided maximum concurrent queries' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.max-concurrent=30/))
    end

    it 'uses the provided query lookback delta' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.lookback-delta=10m/))
    end

    it 'uses the provided maximum concurrent query selects' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.max-concurrent-select=8/))
    end

    it 'uses the provided query replica labels' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.replica-label=instance/)
              .and(match(/--query\.replica-label=region/)))
    end

    it 'enables query auto downsampling' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.auto-downsampling/))
    end

    it 'enables query partial response' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.partial-response/))
    end

    it 'uses the provided query default evaluation interval' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--query\.default-evaluation-interval=2m/))
    end
  end

  describe 'with store configuration' do
    context 'when timeouts provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_STORE_UNHEALTHY_TIMEOUT' => '3m',
            'THANOS_STORE_RESPONSE_TIMEOUT' => '200ms'
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided store unhealthy timeout' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.unhealthy-timeout=3m/))
      end

      it 'uses the provided response timeout' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.response-timeout=200ms/))
      end
    end

    context 'when static addresses provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_STORE_ADDRESSES' => 'localhost:1111,localhost:2222',
            'THANOS_STORE_STRICT_ADDRESSES' => 'localhost:3333,localhost:4444'
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided store addresses' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store=localhost:1111/)
                .and(match(/--store=localhost:2222/)))
      end

      it 'uses the provided store strict addresses' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store-strict=localhost:3333/)
                .and(match(/--store-strict=localhost:4444/)))
      end
    end

    context 'when using sd files provided as file paths' do
      def sd_file1
        File.read('spec/fixtures/example-sd-file-1.yml')
      end

      def sd_file2
        File.read('spec/fixtures/example-sd-file-2.yml')
      end

      def sd_file1_dir
        '/sd-1'
      end

      def sd_file1_path
        "#{sd_file1_dir}/sd-file-1.yml"
      end

      def sd_file2_dir
        '/sd-2'
      end

      def sd_file2_path
        "#{sd_file2_dir}/sd-file-2.yml"
      end

      def escaped_sd_file1
        Shellwords.escape(sd_file1)
      end

      def escaped_sd_file2
        Shellwords.escape(sd_file2)
      end

      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_STORE_SD_FILE_PATHS' =>
              "#{sd_file1_path},#{sd_file2_path}",
            'THANOS_STORE_SD_INTERVAL' => '3m',
            'THANOS_STORE_SD_DNS_INTERVAL' => '10s'
          }
        )

        execute_command("mkdir -p #{sd_file1_dir}")
        execute_command("mkdir -p #{sd_file2_dir}")
        execute_command("echo #{escaped_sd_file1} >> #{sd_file1_path}")
        execute_command("echo #{escaped_sd_file2} >> #{sd_file2_path}")

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided store service discovery file paths' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(%r{--store\.sd-files=/sd-1/sd-file-1.yml})
                .and(match(%r{--store\.sd-files=/sd-2/sd-file-2.yml})))
      end

      it 'uses the provided store service discovery interval' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.sd-interval=3m/))
      end

      it 'uses the provided store service discovery DNS interval' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.sd-dns-interval=10s/))
      end
    end

    context 'when using sd files provided as file object paths' do
      def sd_file1
        File.read('spec/fixtures/example-sd-file-1.yml')
      end

      def sd_file2
        File.read('spec/fixtures/example-sd-file-2.yml')
      end

      def sd_file1_object_path
        "#{s3_bucket_path}/sd-file-1.yml"
      end

      def sd_file2_object_path
        "#{s3_bucket_path}/sd-file-2.yml"
      end

      def create_bucket_object(content, path)
        create_object(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: path,
          content:
        )
      end

      before(:all) do
        create_bucket_object(sd_file1, sd_file1_object_path)
        create_bucket_object(sd_file2, sd_file2_object_path)

        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_STORE_SD_FILE_OBJECT_PATHS' =>
              "#{sd_file1_object_path},#{sd_file2_object_path}",
            'THANOS_STORE_SD_INTERVAL' => '3m',
            'THANOS_STORE_SD_DNS_INTERVAL' => '10s'
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specified service discovery files' do
        config_file_listing = command('ls /opt/thanos/conf/sd/').stdout

        expect(config_file_listing)
          .to(eq("sd-file-1.yml\nsd-file-2.yml\n"))
      end

      it 'uses the correct first service discovery file content' do
        sd_file_1_path = '/opt/thanos/conf/sd/sd-file-1.yml'
        sd_file_1_contents = command("cat #{sd_file_1_path}").stdout

        expect(sd_file_1_contents).to(eq(sd_file1))
      end

      it 'uses the correct second service discovery file content' do
        sd_file_2_path = '/opt/thanos/conf/sd/sd-file-2.yml'
        sd_file_2_contents = command("cat #{sd_file_2_path}").stdout

        expect(sd_file_2_contents).to(eq(sd_file2))
      end

      it 'uses the fetched service discovery files' do
        sd_file_1_path = Regexp.escape('/opt/thanos/conf/sd/sd-file-1.yml')
        sd_file_2_path = Regexp.escape('/opt/thanos/conf/sd/sd-file-2.yml')

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.sd-files=#{sd_file_1_path}/)
                .and(match(/--store\.sd-files=#{sd_file_2_path}/)))
      end

      it 'uses the provided store service discovery interval' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.sd-interval=3m/))
      end

      it 'uses the provided store service discovery DNS interval' do
        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--store\.sd-dns-interval=10s/))
      end
    end
  end

  describe 'with selector labels configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_SELECTOR_LABELS' => 'thing1=value1,thing2=value2'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided selector labels' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--selector-label=thing1="value1"/)
              .and(match(/--selector-label=thing2="value2"/)))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(
      opts
        .merge(
          content: (opts[:env] || {})
                     .to_a
                     .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
                     .join("\n")
        )
    )
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise "\"#{command_string}\" failed with exit code: #{exit_status}"
    end

    command
  end

  def make_bucket(opts)
    execute_command('aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'mb ' \
                    "#{opts[:bucket_path]} " \
                    "--region \"#{opts[:region]}\"")
  end

  def copy_object(opts)
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " \
                    'aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'cp ' \
                    '- ' \
                    "#{opts[:object_path]} " \
                    "--region \"#{opts[:region]}\" " \
                    '--sse AES256')
  end

  def create_object(opts)
    make_bucket(opts)
    copy_object(opts)
  end

  def wait_for_contents(file, content)
    Octopoller.poll(timeout: 30) do
      docker_entrypoint_log = command("cat #{file}").stdout
      docker_entrypoint_log =~ /#{content}/ ? docker_entrypoint_log : :re_poll
    end
  rescue Octopoller::TimeoutError => e
    puts command("cat #{file}").stdout
    raise e
  end

  def execute_docker_entrypoint(opts)
    args = (opts[:arguments] || []).join(' ')
    logfile_path = '/tmp/docker-entrypoint.log'
    start_command = "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &"
    started_indicator = opts[:started_indicator]

    execute_command(start_command)
    wait_for_contents(logfile_path, started_indicator)
  end
end
