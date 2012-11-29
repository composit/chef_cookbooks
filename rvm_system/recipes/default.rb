package "curl"
package "git-core"
 
include_recipe "build-essential"

case node['platform'] 
  when 'centos', 'redhat', 'scientific', 'amazon', 'fedora', 'oracle'
    %w(gcc-c++ patch readline readline-devel zlib zlib-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison).each do |pkg|
      #libyaml-devel iconv-devel
      package pkg
    end
  when 'ubuntu', 'debian'
    %w(build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config).each do |pkg|
      package pkg
    end
  else
    raise 'unknown platform'
end
 
bash "install RVM" do
  user "app"
  #code "bash < <( curl -L http://bit.ly/rvm-install-system-wide )"
  code <<-CODE
    curl -L https://get.rvm.io | sudo bash -s stable
    source /etc/profile.d/rvm.sh
  CODE
  not_if { File.exists? "/usr/local/rvm" }
end

group "rvm" do
  members ["app", "root"]
end

node['active_applications'].each do |name, conf|
  bash "install rubies" do
    code "source /etc/profile.d/rvm.sh && rvm install #{conf['ruby_version']}"
    not_if "source /etc/profile.d/rvm.sh && rvm list | grep #{conf['ruby_version']}"
  end
end
