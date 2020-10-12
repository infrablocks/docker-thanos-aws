require 'spec_helper'

describe 'thanos-compact-aws entrypoint' do
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
  image = 'thanos-compact-aws:latest'
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

  fdescribe 'by default' do
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

    it 'runs thanos compact' do
      expect(process('/opt/thanos/bin/thanos')).to(be_running)
      expect(process('/opt/thanos/bin/thanos').args).to(match(/compact/))
    end

    it 'listens on port 10902 on all interfaces for HTTP traffic' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--http-address=0.0.0.0:10902/))
    end

    it 'uses an HTTP grace period of 2 minutes' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--http-grace-period=2m/))
    end

    it 'uses a data directory of /var/opt/thanos' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--data-dir=\/var\/opt\/thanos/))
    end

    it 'does not include block sync concurrency option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--block-sync-concurrency/))
    end

    it 'does not include consistency delay option' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--consistency-delay/))
    end

    it 'uses the provided object store configuration' do
      config_option = object_store_configuration
          .gsub("\n", " ")
          .gsub('"', '')
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--objstore\.config #{config_option}/))
    end

    it 'does not include any retention configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--retention\.resolution-raw/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--retention\.resolution-5m/))
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--retention\.resolution-1h/))
    end

    it 'does not include any selector configuration' do
      expect(process('/opt/thanos/bin/thanos').args)
          .not_to(match(/--selector\.relabel-config/))
      # covers both relabel config options
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
              'THANOS_BLOCK_SYNC_CONCURRENCY' => '30',
              'THANOS_CONSISTENCY_DELAY' => '30m',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided block sync concurrency' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--block-sync-concurrency=30/))
    end

    it 'uses the provided consistency delay' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--consistency-delay=30m/))
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
        config_option = object_store_configuration
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

  fdescribe 'with retention configuration' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'THANOS_RETENTION_RESOLUTION_RAW' => '14d',
              'THANOS_RETENTION_RESOLUTION_5M' => '30d',
              'THANOS_RETENTION_RESOLUTION_1H' => '90d',
              'THANOS_OBJECT_STORE_CONFIGURATION' =>
                  object_store_configuration
          })

      execute_docker_entrypoint(
          started_indicator: "listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided retention resolution for raw blocks' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--retention\.resolution-raw=14d/))
    end

    it 'uses the provided retention resolution for 5 minute blocks' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--retention\.resolution-5m=30d/))
    end

    it 'uses the provided retention resolution for 1 hour blocks' do
      expect(process('/opt/thanos/bin/thanos').args)
          .to(match(/--retention\.resolution-1h=90d/))
    end
  end

  describe 'with selector configuration' do
    def selector_relabel_configuration
      File.read('spec/fixtures/example-selector-relabel-configuration.yml')
    end

    context 'for relabelling' do
      context 'when provided directly' do
        before(:all) do
          create_env_file(
              endpoint_url: s3_endpoint_url,
              region: s3_bucket_region,
              bucket_path: s3_bucket_path,
              object_path: s3_env_file_object_path,
              env: {
                  'THANOS_SELECTOR_RELABEL_CONFIGURATION' =>
                      selector_relabel_configuration,
                  'THANOS_OBJECT_STORE_CONFIGURATION' =>
                      object_store_configuration
              })

          execute_docker_entrypoint(
              started_indicator: "listening")
        end

        after(:all, &:reset_docker_backend)

        it 'uses the provided selector relabel config' do
          config_option = selector_relabel_configuration
              .gsub("\n", " ")
              .gsub('"', '')
          expect(process('/opt/thanos/bin/thanos').args)
              .to(match(
                  /--selector\.relabel-config #{Regexp.escape(config_option)}/))
        end
      end

      context 'when passed an object path' do
        before(:all) do
          selector_relabel_config_file_object_path = "#{s3_bucket_path}/selector-relabelling.yml"

          create_object(
              endpoint_url: s3_endpoint_url,
              region: s3_bucket_region,
              bucket_path: s3_bucket_path,
              object_path: selector_relabel_config_file_object_path,
              content: selector_relabel_configuration)
          create_env_file(
              endpoint_url: s3_endpoint_url,
              region: s3_bucket_region,
              bucket_path: s3_bucket_path,
              object_path: s3_env_file_object_path,
              env: {
                  'THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_OBJECT_PATH' =>
                      selector_relabel_config_file_object_path,
                  'THANOS_OBJECT_STORE_CONFIGURATION' =>
                      object_store_configuration
              })

          execute_docker_entrypoint(
              started_indicator: "listening")
        end

        after(:all, &:reset_docker_backend)

        it 'fetches the specific selector relabel config file and passes its path' do
          config_file_listing = command('ls /opt/thanos/conf').stdout

          expect(config_file_listing).to(eq("selector-relabelling.yml\n"))

          config_file_path = '/opt/thanos/conf/selector-relabelling.yml'
          config_file_contents = command("cat #{config_file_path}").stdout

          expect(config_file_contents).to(eq(selector_relabel_configuration))
          expect(process('/opt/thanos/bin/thanos').args)
              .to(match(
                  /--selector\.relabel-config-file=#{Regexp.escape(config_file_path)}/))
        end
      end

      context 'when passed a filesystem path' do
        before(:all) do
          create_env_file(
              endpoint_url: s3_endpoint_url,
              region: s3_bucket_region,
              bucket_path: s3_bucket_path,
              object_path: s3_env_file_object_path,
              env: {
                  'THANOS_SELECTOR_RELABEL_CONFIGURATION_FILE_PATH' =>
                      '/selector-relabel-config.yml',
                  'THANOS_OBJECT_STORE_CONFIGURATION' =>
                      object_store_configuration
              })

          execute_command(
              "echo \"#{selector_relabel_configuration}\" > /selector-relabel-config.yml")
          execute_command(
              "chown thanos:thanos /selector-relabel-config.yml")

          execute_docker_entrypoint(
              started_indicator: "listening")
        end

        after(:all, &:reset_docker_backend)

        it 'uses the provided file path as the selector relabel config path' do
          expect(process('/opt/thanos/bin/thanos').args)
              .to(match(
                  /--selector\.relabel-config-file=\/selector-relabel-config.yml/))
        end
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
