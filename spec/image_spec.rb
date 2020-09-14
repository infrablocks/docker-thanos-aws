require 'spec_helper'

xdescribe 'image' do
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

  it 'puts the thanos user in the thanos group' do
    expect(user('thanos'))
        .to(belong_to_primary_group('thanos'))
  end

  it 'has the correct ownership on the thanos directory' do
    expect(file('/opt/thanos')).to(be_owned_by('thanos'))
    expect(file('/opt/thanos')).to(be_grouped_into('thanos'))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end