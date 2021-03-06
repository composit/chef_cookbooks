execute "apt-get update" do
  action :nothing
end

apt_repository "10gen" do
  uri "http://downloads-distro.mongodb.org/repo/ubuntu-upstart"
  distribution "dist"
  components ["10gen"]
  keyserver "keyserver.ubuntu.com"
  key "7F0CEB10"
  action :add
  notifies :run, "execute[apt-get update]", :immediately
end

package "mongodb" do
  package_name "mongodb-10gen"
end
