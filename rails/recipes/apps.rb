include_recipe "nginx"
include_recipe "rails::app_dependencies"
include_recipe "unicorn"
include_recipe "bluepill"
include_recipe "users"

package 'git'
gem_package "bundler"

if node[:active_applications]
  
  directory "/etc/nginx/sites-include" do
    mode 0755
  end
  
  node[:active_applications].each do |app_name, conf|
    app_root = "/u/apps/#{app_name}"
  
    full_name = "#{app_name}_#{conf[:env]}"
    filename = "#{filename}_#{conf[:env]}.conf"

    domain = conf["domain"]

    #ssl_name = domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
    ssl_name = domain.split( ' ' )[0].gsub ".", "_"
    
    #ssl_certificate ssl_name

    template "/etc/nginx/sites-include/#{full_name}" do
      source "app_nginx_include.conf.erb"
      variables :full_name => full_name, :conf => conf, :app_name => app_name
      notifies :reload, resources(:service => "nginx")
    end
              
    template "/etc/nginx/sites-available/#{full_name}.conf" do
      source "app_nginx.conf.erb"
      variables :full_name => full_name, :conf => conf, :app_name => app_name, :domain => domain, :ssl_only => ( conf[:ssl_only].to_s == "true" ), :ssl_name => ssl_name
      notifies :reload, resources(:service => "nginx")
    end

    common_variables = {
      :preload => true,
      :app_root => app_root,
      :full_name => full_name,
      :app_name => app_name,
      :env => conf[:env],
      :user => "app",
      :group => "app",
      :listen_port => 8600
    }

    template "#{node[:unicorn][:config_path]}/#{full_name}" do
      mode 0644
      source "unicorn.conf.erb"
      variables common_variables
    end
    
    template "#{node[:bluepill][:conf_dir]}/#{full_name}.pill" do
      mode 0644
      source "bluepill_unicorn.conf.erb"
      variables common_variables.merge(
        :interval => node[:rails][:monitor_interval],
        :memory_limit => node[:rails][:memory_limit],
        :cpu_limit => node[:rails][:cpu_limit])
    end
    
    bluepill_service full_name do
      action [:enable, :load, :start]
    end
    
    nginx_site full_name do
      action :enable
    end
    
    logrotate full_name do
      files ["/u/apps/#{app_name}/current/log/*.log"]
      frequency "daily"
      rotate_count 14
      compress true
      restart_command "/etc/init.d/nginx reload > /dev/null"
    end
  end
end
