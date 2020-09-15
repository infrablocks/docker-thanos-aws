require 'spec_helper'

describe 'thanos-aws entrypoint' do
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
  image = 'thanos-aws:latest'
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
          arguments: ["sidecar"],
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs thanos' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
    end

    it 'logs using JSON' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--log\.format=json/))
    end

    it 'logs at info level' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--log\.level=info/))
    end

    it 'has no tracing configured' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--tracing\.config/))
    end

    it 'runs with the thanos user' do
      expect(process('/opt/thanos/bin/thanos').user)
          .to(eq('thanos'))
    end

    it 'runs with the thanos group' do
      expect(process('/opt/thanos/bin/thanos').group)
          .to(eq('thanos'))
    end
  end

  describe 'with logging configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_LOG_LEVEL' => 'debug',
              'THANOS_LOG_FORMAT' => 'logfmt'
          })

      execute_docker_entrypoint(
          arguments: ["sidecar"],
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'logs using the provided format' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--log\.format=logfmt/))
    end

    it 'logs at the provided level' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--log\.level=debug/))
    end
  end

  describe 'with tracing configuration' do
    def tracing_configuration
      File.read('spec/fixtures/example-tracing-configuration.yml')
    end

    context 'when passed directly' do

      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_TRACING_CONFIGURATION' => tracing_configuration
            })

        execute_docker_entrypoint(
            arguments: ["sidecar"],
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'passes the provided tracing config' do
        config_option=tracing_configuration
            .gsub("\n", " ")
            .gsub('"', '')
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(/--tracing\.config #{config_option}/))
      end
    end

    context 'when passed an object path for a config file' do
      before(:all) do
        tracing_config_file_object_path = "#{s3_bucket_path}/tracing.yml"

        create_object(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: tracing_config_file_object_path,
            content: tracing_configuration)
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_TRACING_CONFIGURATION_FILE_OBJECT_PATH' =>
                    tracing_config_file_object_path
            })

        execute_docker_entrypoint(
            arguments: ["sidecar"],
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'fetches the specific tracing config file and passes its path' do
        config_file_listing = command('ls /opt/thanos/conf').stdout

        expect(config_file_listing).to(eq("tracing.yml\n"))

        config_file_path = '/opt/thanos/conf/tracing.yml'
        config_file_contents = command("cat #{config_file_path}").stdout

        expect(config_file_contents).to(eq(tracing_configuration))
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--tracing\.config-file=#{Regexp.escape(config_file_path)}/))
      end
    end

    context 'when passed a filesystem path for a config file' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
            env: {
                'THANOS_TRACING_CONFIGURATION_FILE_PATH' =>
                    '/tracing-config.yml'
            })

        execute_command(
            "echo \"#{tracing_configuration}\" > /tracing-config.yml")
        execute_command(
            "chown thanos:thanos /tracing-config.yml")

        execute_docker_entrypoint(
            arguments: ["sidecar"],
            started_indicator: "listening")
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided file path as the tracing config path' do
        expect(process('/opt/thanos/bin/thanos').args)
            .to(match(
                /--tracing\.config-file=\/tracing-config.yml/))
      end
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
    args = opts[:arguments].join(' ')

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
