require 'spec_helper'

describe 'thanos-sidecar-aws entrypoint' do
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
  image = 'thanos-sidecar-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
          'NetworkMode' => 'docker_thanos_aws_test_default'
      }
  }

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
          object_path: s3_env_file_object_path)

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs thanos sidecar' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
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

    it 'disables gRPC TLS' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--grpc-server-tls-cert=( |$)/))
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--grpc-server-tls-key=( |$)/))
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--grpc-server-tls-client-ca=( |$)/))
    end

    it 'uses a prometheus URL of http://localhost:9090' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--prometheus.url=http:\/\/localhost:9090/))
    end

    it 'uses a prometheus ready timeout of 10 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--prometheus.ready_timeout=10m/))
    end

    it 'uses a receive connection pool size of zero' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--receive.connection-pool-size=0/))
    end

    it 'uses a receive connection pool size per host of 100' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--receive.connection-pool-size-per-host=100/))
    end

    it 'uses a TSDB path of /var/opt/prometheus' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--tsdb.path=\/var\/opt\/prometheus/))
    end

    it 'disables the reloader' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--reloader.config-file=( |$)/))
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--reloader.config-envsubst-file=( |$)/))
    end

    it 'uses a reloader watch interval of 3 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--reloader.watch-interval=3m/))
    end

    it 'uses a reloader retry interval of 5 seconds' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--reloader.retry-interval=5s/))
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
              'THANOS_GRPC_GRACE_PERIOD' => '4m'
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
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided prometheus URL' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--prometheus.url=http:\/\/localhost:9191/))
    end

    it 'uses the provided prometheus ready timeout' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--prometheus.ready_timeout=5m/))
    end
  end

  describe 'with receive configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_RECEIVE_CONNECTION_POOL_SIZE' => '200',
              'THANOS_RECEIVE_CONNECTION_POOL_SIZE_PER_HOST' => '50'
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided receive connection pool size' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--receive.connection-pool-size=200/))
    end

    it 'uses the provided receive connection pool size per host' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--receive.connection-pool-size-per-host=50/))
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
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided TSDB path' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--tsdb\.path=\/data/))
    end
  end

  describe 'with reloader configuration' do
    before(:all) do
      prometheus_config =
          File.read('spec/fixtures/example-prometheus-config.yml')
      escaped_prometheus_config = Shellwords.escape(prometheus_config)

      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_RELOADER_CONFIGURATION_FILE' =>
                  '/opt/prometheus/prometheus.yml',
              'THANOS_RELOADER_WATCH_INTERVAL' => '5m',
              'THANOS_RELOADER_RETRY_INTERVAL' => '4s'
          })

      prometheus_config_dir = "/opt/prometheus/"
      prometheus_config_file = "#{prometheus_config_dir}prometheus.yml"

      execute_command(
          "mkdir -p #{prometheus_config_dir}")
      execute_command(
          "echo #{escaped_prometheus_config} >> #{prometheus_config_file}")

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided reloader configuration file' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--reloader\.config-file=\/opt\/prometheus\/prometheus.yml/))
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

  describe 'with reloader configuration' do
    before(:all) do
      prometheus_config =
          File.read('spec/fixtures/example-prometheus-config.yml')
      escaped_prometheus_config = Shellwords.escape(prometheus_config)

      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_RELOADER_CONFIGURATION_ENVSUBST_FILE' =>
                  '/opt/prometheus/prometheus.yml'
          })

      prometheus_config_dir = "/opt/prometheus/"
      prometheus_config_file = "#{prometheus_config_dir}prometheus.yml"

      execute_command(
          "mkdir -p #{prometheus_config_dir}")
      execute_command(
          "echo #{escaped_prometheus_config} >> #{prometheus_config_file}")

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided reloader configuration envsubst file' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(
              /--reloader\.config-envsubst-file=\/opt\/prometheus\/prometheus.yml/))
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
