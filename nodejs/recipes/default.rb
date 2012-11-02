case node['platform']
  when 'centos', 'redhat', 'scientific', 'amazon', 'fedora'
    file = '/usr/local/src/nodejs-stable-release.noarch.rpm'
 
    remote_file file do
      source 'http://nodejs.tchol.org/repocfg/el/nodejs-stable-release.noarch.rpm'
      action :create_if_missing
    end
 
    yum_package 'nodejs-stable-release' do
      source file
      options '--nogpgcheck'
    end
 
    %w{ nodejs nodejs-compat-symlinks npm }.each do |pkg|
      package pkg
    end
  when 'ubuntu'
    apt_repository 'node.js' do
      uri 'http://ppa.launchpad.net/chris-lea/node.js/ubuntu'
      distribution node['lsb']['codename']
      components ['main']
      keyserver "keyserver.ubuntu.com"
      key "C7917B12"
      action :add
    end
 
    %w{ nodejs npm }.each do |pkg|
      package pkg
    end
  else
    raise "unknown platform"
end
