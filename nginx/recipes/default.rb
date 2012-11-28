include_recipe "bluepill"

package "nginx"

template "/etc/logrotate.d/nginx" do
  source "logrotate.erb"
  owner "root"
  group "root"
  mode 00644
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
end

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
  action :create
end

["sites-available", "sites-enabled"].each do |dir_name|
  directory "#{node[:nginx][:dir]}/#{dir_name}" do
    mode 0755
    owner node[:nginx][:user]
    action :create
  end
end

cookbook_file "/etc/nginx/mime.types"

directory "/etc/nginx/helpers"

# helpers to be included in your vhosts
node[:nginx][:helpers].each do |h|
  template "/etc/nginx/helpers/#{h}.conf" do
    notifies :reload, resources(:service => "nginx")
  end
end

# server-wide defaults, automatically loaded
node[:nginx][:extras].each do |ex|
  template "/etc/nginx/conf.d/#{ex}.conf" do
    notifies :reload, resources(:service => "nginx")
  end
end  

template "#{node[:nginx][:dir]}/nginx.conf" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, resources(:service => "nginx")
end

template "#{node['bluepill']['conf_dir']}/nginx.pill" do
  source "nginx.pill.erb"
  mode 0644
  variables(
    :working_dir => node[:nginx][:dir],
    :src_binary => node[:nginx][:binary],
    :nginx_dir => node[:nginx][:dir],
    :log_dir => node[:nginx][:log_dir],
    :pid => node[:nginx][:pid]
  )
end

bluepill_service "nginx" do
  action [ :enable, :load ]
end

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  reload_command "[[ -f #{node[:nginx][:pid]} ]] && kill -HUP `cat #{node[:nginx][:pid]}` || true"
  action :nothing
end

#service "nginx" do
#  action [ :enable, :start ]
#end
