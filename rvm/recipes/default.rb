package "curl"
package "git-core"
 
include_recipe "build-essential"
 
%w(libreadline5-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev).each do |pkg|
  package pkg
end
 
bash "install RVM" do
  user "app"
  code "bash < <( curl -L https://get.rvm.io | bash -s stable --ruby )"
  #code "bash < <( curl -L http://bit.ly/rvm-install-system-wide )"
  not_if "rvm --version"
end
 
bash "install specific rubies" do
  user "app"
  node["active_applications"].each do |app_name, conf|
    code "rvm install #{conf["ruby-version"]}"
    not_if "rvm list | grep #{conf["ruby-version"]}"
  end
end
