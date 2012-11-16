include_recipe "nginx"

directory "/var/cache/nginx/proxy-cache" do
  owner node[:nginx][:user]
end

template "/etc/nginx/sites-available/gravatar.conf" do
  notifies :reload, resources(:service => "nginx")
end

nginx_site 'gravatar' do
  action :enable
end
