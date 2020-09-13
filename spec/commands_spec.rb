require 'spec_helper'

describe 'commands' do
  image = 'thanos-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it "includes the thanos command" do
    expect(command('/opt/thanos/bin/thanos --version').stderr)
        .to(match(/0.15.0/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
