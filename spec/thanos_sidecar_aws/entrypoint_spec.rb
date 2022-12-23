# frozen_string_literal: true

require 'spec_helper'

describe 'thanos-sidecar-aws entrypoint' do
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
    'thanos-sidecar-aws:latest'
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

    it 'runs thanos' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
    end

    it 'runs thanos sidecar subcommand' do
      expect(process('/opt/thanos/bin/thanos').args).to(match(/sidecar/))
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

    it 'does not pass gRPC TLS cert' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-cert/))
    end

    it 'does not pass gRPC TLS key' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-key/))
    end

    it 'does not pass gRPC TLS client CA' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--grpc-server-tls-client-ca/))
    end

    it 'uses a prometheus URL of http://localhost:9090' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(%r{--prometheus.url=http://localhost:9090}))
    end

    it 'uses a prometheus ready timeout of 10 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--prometheus.ready_timeout=10m/))
    end

    it 'uses a TSDB path of /var/opt/prometheus' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(%r{--tsdb.path=/var/opt/prometheus}))
    end

    it 'disables the reloader config file' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader\.config-file=( |$)/))
    end

    it 'disables the reloader config envsubst file' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader\.config-envsubst-file=( |$)/))
    end

    it 'disables the reloader rule dir' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--reloader\.rule-dir/))
    end

    it 'uses a reloader watch interval of 3 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader.watch-interval=3m/))
    end

    it 'uses a reloader retry interval of 5 seconds' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader.retry-interval=5s/))
    end

    it 'does not pass object store shipping config file' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--objstore\.config-file/))
    end

    it 'does not pass object store shipping config' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--objstore\.config/))
    end

    it 'does not instruct shipper to upload compacted blocks' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--shipper\.upload-compacted/))
    end

    it 'does not include a start time for metrics' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--min-time/))
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

  describe 'with gRPC TLS configuration' do
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

      it 'uses the correct server TLS certificate' do
        cert_path = '/opt/thanos/conf/server-cert.pem'
        cert_contents = command("cat #{cert_path}").stdout

        expect(cert_contents).to(eq(cert))
      end

      it 'uses the correct server TLS key' do
        key_path = '/opt/thanos/conf/server-key.pem'
        key_contents = command("cat #{key_path}").stdout

        expect(key_contents).to(eq(key))
      end

      it 'uses the correct server TLS client CA' do
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

  describe 'with prometheus configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_PROMETHEUS_URL' => 'http://localhost:9191',
          'THANOS_PROMETHEUS_READY_TIMEOUT' => '5m'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided prometheus URL' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(%r{--prometheus.url=http://localhost:9191}))
    end

    it 'uses the provided prometheus ready timeout' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--prometheus.ready_timeout=5m/))
    end
  end

  describe 'with tsdb configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_TSDB_PATH' => '/data'
        }
      )

      execute_command('mkdir /data')

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided TSDB path' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(%r{--tsdb\.path=/data}))
    end
  end

  describe 'with reloader configuration file, rules and intervals' do
    def prometheus_config
      File.read('spec/fixtures/example-prometheus-configuration.yml')
    end

    def escaped_prometheus_config
      Shellwords.escape(prometheus_config)
    end

    def rule_file1
      File.read('spec/fixtures/example-prometheus-rule-file-1.yml')
    end

    def escaped_rule_file1
      Shellwords.escape(rule_file1)
    end

    def rule_file2
      File.read('spec/fixtures/example-prometheus-rule-file-2.yml')
    end

    def escaped_rule_file2
      Shellwords.escape(rule_file2)
    end

    def prometheus_config_dir
      '/opt/prometheus'
    end

    def prometheus_config_file
      "#{prometheus_config_dir}/prometheus.yml"
    end

    def prometheus_rules_dir1
      "#{prometheus_config_dir}/rules-1"
    end

    def prometheus_rule_file1
      "#{prometheus_rules_dir1}/rule-file-1.yml"
    end

    def prometheus_rules_dir2
      "#{prometheus_config_dir}/rules-2"
    end

    def prometheus_rule_file2
      "#{prometheus_rules_dir2}/rule-file-2.yml"
    end

    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_RELOADER_CONFIGURATION_FILE' =>
            '/opt/prometheus/prometheus.yml',
          'THANOS_RELOADER_RULE_DIRECTORIES' =>
            '/opt/prometheus/rules-1,/opt/prometheus/rules-2',
          'THANOS_RELOADER_WATCH_INTERVAL' => '5m',
          'THANOS_RELOADER_RETRY_INTERVAL' => '4s'
        }
      )

      execute_command("mkdir -p #{prometheus_config_dir}")
      execute_command("mkdir -p #{prometheus_rules_dir1}")
      execute_command("mkdir -p #{prometheus_rules_dir2}")

      write_file(escaped_prometheus_config, prometheus_config_file)
      write_file(escaped_rule_file1, prometheus_rule_file1)
      write_file(escaped_rule_file2, prometheus_rule_file2)

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided reloader configuration file' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              %r{--reloader\.config-file=/opt/prometheus/prometheus.yml}
            ))
    end

    it 'uses the provided reloader rules directory' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(%r{--reloader\.rule-dir /opt/prometheus/rules-1})
              .and(match(%r{--reloader\.rule-dir /opt/prometheus/rules-2})))
    end

    it 'uses the provided reloader watch interval' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader\.watch-interval=5m/))
    end

    it 'uses the provided reloader retry interval' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--reloader\.retry-interval=4s/))
    end
  end

  describe 'with reloader configuration envsubst file' do
    before(:all) do
      prometheus_config =
        File.read('spec/fixtures/example-prometheus-configuration.yml')
      escaped_prometheus_config = Shellwords.escape(prometheus_config)

      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_RELOADER_CONFIGURATION_ENVSUBST_FILE' =>
            '/opt/prometheus/prometheus.yml'
        }
      )

      prometheus_config_dir = '/opt/prometheus/'
      prometheus_config_file = "#{prometheus_config_dir}prometheus.yml"

      execute_command("mkdir -p #{prometheus_config_dir}")
      write_file(escaped_prometheus_config, prometheus_config_file)

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided reloader configuration envsubst file' do
      config_envsubst_file_path =
        Regexp.escape('/opt/prometheus/prometheus.yml')
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(
              /--reloader\.config-envsubst-file=#{config_envsubst_file_path}/
            ))
    end
  end

  describe 'with object store configuration' do
    def object_store_configuration
      File.read('spec/fixtures/example-object-store-configuration.yml')
    end

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
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'passes the provided object store config' do
        config_option = object_store_configuration
                        .gsub("\n", ' ')
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
          content: object_store_configuration
        )
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'THANOS_OBJECT_STORE_CONFIGURATION_FILE_OBJECT_PATH' =>
              object_store_config_file_object_path
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specific object store config file' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing).to(eq("objstore.yml\n"))
      end

      it 'uses the correct object store config file content' do
        config_file_path = '/opt/thanos/conf/objstore.yml'
        config_file_contents = command("cat #{config_file_path}").stdout

        expect(config_file_contents).to(eq(object_store_configuration))
      end

      it 'passes the specific object store config file path' do
        config_file_path = '/opt/thanos/conf/objstore.yml'

        expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
                /--objstore\.config-file=#{Regexp.escape(config_file_path)}/
              ))
      end
    end
  end

  describe 'with shipper upload compacted enabled' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_SHIPPER_UPLOAD_COMPACTED_ENABLED' => 'yes'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'includes shipper upload compacted as true' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--shipper\.upload-compacted/))
    end
  end

  describe 'with shipper upload compacted disabled' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_SHIPPER_UPLOAD_COMPACTED_ENABLED' => 'no'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'does not include shipper upload compacted option' do
      expect(process('/opt/thanos/bin/thanos').args)
        .not_to(match(/--shipper\.upload-compacted/))
    end
  end

  describe 'with minimum time configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'THANOS_MINIMUM_TIME' => '2020-09-22T15:31:29Z'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided minimum time' do
      expect(process('/opt/thanos/bin/thanos').args)
        .to(match(/--min-time=2020-09-22T15:31:29Z/))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  rescue Docker::Error::NotFoundError => e
    puts e.message
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

  def write_file(contents, path)
    execute_command(
      "echo \"#{contents}\" > #{path}"
    )
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
