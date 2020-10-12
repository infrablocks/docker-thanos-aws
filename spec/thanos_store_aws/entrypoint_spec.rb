require 'spec_helper'

describe 'thanos-store-aws entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
      'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
      'AWS_S3_BUCKET_REGION' => s3_bucket_region,
      'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'thanos-store-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
          'NetworkMode' => 'docker_thanos_aws_test_default'
      }
  }

  def object_store_configuration
    File.read('spec/fixtures/example-object-store-configuration.yml')
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
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs thanos store' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
      expect(process('/opt/thanos/bin/thanos').args).to(match(/store/))
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

    it 'disables gRPC server TLS' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--grpc-server-tls-cert/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--grpc-server-tls-key/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--grpc-server-tls-client-ca/))
    end

    it 'uses a data directory of /var/opt/thanos' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--data-dir=\/var\/opt\/thanos/))
    end

    it 'does not include chunk pool size option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--chunk-pool-size/))
    end

    it 'does not include sync block duration option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--sync-block-duration/))
    end

    it 'does not include block sync concurrency option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--block-sync-concurrency/))
    end

    it 'does not include consistency delay option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--consistency-delay/))
    end

    it 'does not include ignore deletion marks delay option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--ignore-deletion-marks-delay/))
    end

    it 'does not include store gRPC configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--store\.grpc\.series-sample-limit/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--store\.grpc\.series-max-concurrency/))
    end

    it 'does not include index cache configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--index-cache-size/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--index-cache\.config-file/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--index-cache\.config/))
    end

    it 'uses the provided object store configuration' do
      config_option=object_store_configuration
          .gsub("\n", " ")
          .gsub('"', '')
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--objstore\.config #{config_option}/))
    end

    it 'does not include any time configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--min-time/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--max-time/))
    end

    it 'does not include any web configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--web\.external-prefix/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--web\.prefix-header/))
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
              'THANOS_HTTP_GRACE_PERIOD' => '4m',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
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
              'THANOS_GRPC_GRACE_PERIOD' => '4m',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
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
                'THANOS_GRPC_SERVER_TLS_CLIENT_CA_FILE_PATH' => '/client-ca.pem',
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_command(
            "echo \"#{cert}\" > /cert.pem")
        execute_command(
            "echo \"#{key}\" > /key.pem")
        execute_command(
            "echo \"#{client_ca}\" > /client-ca.pem")
        execute_command(
            "chown thanos:thanos /cert.pem")
        execute_command(
            "chown thanos:thanos /key.pem")
        execute_command(
            "chown thanos:thanos /client-ca.pem")

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided file path as the server TLS cert' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-cert=\/cert.pem/))
      end

      it 'uses the provided file path as the server TLS key' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-key=\/key.pem/))
      end

      it 'uses the provided file path as the server TLS client CA' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-client-ca=\/client-ca.pem/))
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

      before(:all) do
        cert_object_path = "#{s3_bucket_path}/cert.pem"
        key_object_path = "#{s3_bucket_path}/key.pem"
        client_ca_object_path = "#{s3_bucket_path}/client-ca.pem"

        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: cert_object_path,
            content: cert)
        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: key_object_path,
            content: key)
        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: client_ca_object_path,
            content: client_ca)
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
                    client_ca_object_path,
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specified server TLS certificate, key and client CA' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing)
            .to(eq([
                "server-cert.pem",
                "server-client-ca.pem",
                "server-key.pem"
            ].join("\n") + "\n"))

        cert_path = '/opt/thanos/conf/server-cert.pem'
        cert_contents = command("cat #{cert_path}").stdout

        key_path = '/opt/thanos/conf/server-key.pem'
        key_contents = command("cat #{key_path}").stdout

        client_ca_path = '/opt/thanos/conf/server-client-ca.pem'
        client_ca_contents = command("cat #{client_ca_path}").stdout

        expect(cert_contents).to(eq(cert))
        expect(key_contents).to(eq(key))
        expect(client_ca_contents).to(eq(client_ca))
      end

      it 'uses the fetched TLS certificate' do
        cert_path = '/opt/thanos/conf/server-cert.pem'

        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-cert=#{Regexp.escape(cert_path)}/))
      end

      it 'uses the fetched TLS key' do
        key_path = '/opt/thanos/conf/server-key.pem'

        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-key=#{Regexp.escape(key_path)}/))
      end

      it 'uses the fetched TLS client CA' do
        client_ca_path = '/opt/thanos/conf/server-client-ca.pem'

        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--grpc-server-tls-client-ca=#{Regexp.escape(client_ca_path)}/))
      end
    end
  end

  describe 'with data directory configuration' do
    def data_directory
      '/data'
    end

    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_DATA_DIRECTORY' => data_directory,
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_command(
          "mkdir -p #{data_directory}")
      execute_command(
          "chown thanos:thanos #{data_directory}")

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided data directory' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--data-dir=#{Regexp.escape(data_directory)}/))
    end
  end

    describe 'with top-level configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_CHUNK_POOL_SIZE' => '3GB',
              'THANOS_SYNC_BLOCK_DURATION' => '5m',
              'THANOS_BLOCK_SYNC_CONCURRENCY' => '30',
              'THANOS_CONSISTENCY_DELAY' => '30m',
              'THANOS_IGNORE_DELETION_MARKS_DELAY' => '48h',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided chunk pool size' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--chunk-pool-size=3GB/))
    end

    it 'uses the provided sync block duration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--sync-block-duration=5m/))
    end

    it 'uses the provided block sync concurrency' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--block-sync-concurrency=30/))
    end

    it 'uses the provided consistency delay' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--consistency-delay=30m/))
    end

    it 'uses the provided ignore deletion marks delay' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--ignore-deletion-marks-delay=48h/))
    end
  end

  describe 'with index cache configuration' do
    def index_cache_configuration
      File.read('spec/fixtures/example-index-cache-configuration.yml')
    end

    context 'when index cache size provided' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_INDEX_CACHE_SIZE' => '1GB',
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided index cache size' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--index-cache-size=1GB/))
      end
    end

    context 'when index cache config provided directly' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_INDEX_CACHE_CONFIGURATION' =>
                    index_cache_configuration,
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided index cache config' do
        config_option=index_cache_configuration
            .gsub("\n", " ")
            .gsub('"', '')
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--index-cache\.config #{config_option}/))
      end
    end

    context 'when passed an object path for index cache config file' do
      before(:all) do
        index_cache_config_file_object_path = "#{s3_bucket_path}/index-cache.yml"

        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: index_cache_config_file_object_path,
            content: index_cache_configuration)
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_INDEX_CACHE_CONFIGURATION_FILE_OBJECT_PATH' =>
                    index_cache_config_file_object_path,
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specific index cache config file and passes its path' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing).to(eq("index-cache.yml\n"))

        config_file_path = '/opt/thanos/conf/index-cache.yml'
        config_file_contents = command("cat #{config_file_path}").stdout

        expect(config_file_contents).to(eq(index_cache_configuration))
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--index-cache\.config-file=#{Regexp.escape(config_file_path)}/))
      end
    end

    context 'when passed a filesystem path for index cache config file' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_INDEX_CACHE_CONFIGURATION_FILE_PATH' =>
                    '/index-cache-config.yml',
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_command(
            "echo \"#{index_cache_configuration}\" > /index-cache-config.yml")
        execute_command(
            "chown thanos:thanos /index-cache-config.yml")

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided file path as the index cache config path' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--index-cache\.config-file=\/index-cache-config.yml/))
      end
    end
  end

  describe 'with store gRPC configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_STORE_GRPC_SERIES_SAMPLE_LIMIT' => '20',
              'THANOS_STORE_GRPC_SERIES_MAX_CONCURRENCY' => '30',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided store gRPC series sample limit' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--store\.grpc\.series-sample-limit=20/))
    end

    it 'uses the provided store gRPC series max concurrency' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--store\.grpc\.series-max-concurrency=30/))
    end
  end

  describe 'with object store configuration' do
    context 'when passed directly' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_OBJECT_STORE_CONFIGURATION' =>
                    object_store_configuration
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'passes the provided object store config' do
        config_option=object_store_configuration
            .gsub("\n", " ")
            .gsub('"', '')
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(/--objstore\.config #{config_option}/))
      end
    end

    context 'when passed an object path for a config file' do
      before(:all) do
        object_store_config_file_object_path = "#{s3_bucket_path}/objstore.yml"

        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: object_store_config_file_object_path,
            content: object_store_configuration)
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_OBJECT_STORE_CONFIGURATION_FILE_OBJECT_PATH' =>
                    object_store_config_file_object_path
            })

        execute_docker_entrypoint(
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specific object store config file and passes its path' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing).to(eq("objstore.yml\n"))

        config_file_path = '/opt/thanos/conf/objstore.yml'
        config_file_contents = command("cat #{config_file_path}").stdout

        expect(config_file_contents).to(eq(object_store_configuration))
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--objstore\.config-file=#{Regexp.escape(config_file_path)}/))
      end
    end
  end

  describe 'with time configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_MINIMUM_TIME' => '2020-09-22T15:31:29Z',
              'THANOS_MAXIMUM_TIME' => '2020-09-23T00:00:00Z',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided minimum time' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--min-time=2020-09-22T15:31:29Z/))
    end

    it 'uses the provided maximum time' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--max-time=2020-09-23T00:00:00Z/))
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
              'THANOS_WEB_EXTERNAL_PREFIX' => '/query',
              'THANOS_WEB_PREFIX_HEADER' => 'X-Forwarded-Prefix',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided web external prefix' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--web\.external-prefix=\/query/))
    end

    it 'uses the provided web prefix header' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--web\.prefix-header=X-Forwarded-Prefix/))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
        .merge(content: (opts[:env] || {})
            .to_a
            .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
            .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    args = (opts[:arguments] || []).join(' ')

    execute_command(
        "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 5) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end
