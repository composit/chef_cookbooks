package "curl"
package "git-core"
 
include_recipe "build-essential"
 
case node['platform']
  when 'centos', 'redhat', 'scientific', 'amazon', 'fedora', 'oracle'
    %w(gcc-c++ patch readline readline-devel zlib zlib-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison).each do |pkg|
      # libyaml-devel, iconv-devel
      package pkg
    end
  when 'ubuntu'
    %w(build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config).each do |pkg|
      package pkg
    end
  else
    raise "unknown platform"
end
 
bash "install RVM" do
  user "app"
  code "sudo -u app curl -L https://get.rvm.io | bash -s stable"
  not_if "ls -a /home/app/ | grep .rvm"
end
cookbook_file "/etc/profile.d/rvm.sh"
 
bash "install specific rubies" do
  user "app"
  node["active_applications"].each do |app_name, conf|
    code "rvm install #{conf["ruby-version"]}"
    not_if "rvm list | grep #{conf["ruby-version"]}"
  end
end
