package "curl"
package "git-core"
 
include_recipe "build-essential"

case node['platform'] 
  when 'centos', 'redhat', 'scientific', 'amazon', 'fedora', 'oracle'
    %w(gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel).each do |pkg|
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
  code "curl -L https://get.rvm.io | sudo bash -s stable"
  not_if { File.exists? "/usr/local/rvm" }
end

group "rvm" do
  members ["app", "root"]
end

bash "install rubies" do
  node['active_applications'].each do |name, conf|
    code "rvm install #{conf['ruby_version']}"
    not_if "rvm list | grep #{conf['ruby_version']}"
  end
end

#bash "install REE in RVM" do
#  user "root"
#  code "rvm install ree"
#  not_if "rvm list | grep ree"
#end
 
#bash "make REE the default ruby" do
#  user "root"
#  code "rvm --default ree"
#end
 
#gem_package "chef" # re-install the chef gem into REE to enable subsequent chef-client runs
