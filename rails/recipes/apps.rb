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
  
  node[:active_applications].each do |app_id, conf|
    app_root = "/u/apps/#{app_id}"
  
    domain = conf["domain"]

    #ssl_name = domain =~ /\*\.(.+)/ ? "#{$1}_wildcard" : domain
    ssl_name = domain.split( ' ' )[0].gsub ".", "_"
    ssl = [conf[:ssl_only], conf[:ssl]].include? 'true'
    
    #ssl_certificate ssl_name

    template "/etc/nginx/sites-include/#{app_id}" do
      source "app_nginx_include.conf.erb"
      variables :app_id => app_id, :conf => conf, :app_id => app_id
      notifies :reload, resources(:service => "nginx")
    end
              
    template "/etc/nginx/sites-available/#{app_id}.conf" do
      source "app_nginx.conf.erb"
      variables :app_id => app_id, :conf => conf, :app_id => app_id, :domain => domain, :ssl => ssl, :ssl_only => ( conf[:ssl_only].to_s == "true" ), :ssl_name => ssl_name
      notifies :reload, resources(:service => "nginx")
    end

    common_variables = {
      :preload => true,
      :app_root => app_root,
      :app_id => app_id,
      :env => conf[:env],
      :user => "app",
      :group => "app",
      :listen_port => 8600,
      :bundle_wrapper => File.join( '/usr/local/rvm/bin', "#{conf[:ruby_version]}_bundle" )
    }

    template "#{node[:unicorn][:config_path]}/#{app_id}" do
      mode 0644
      source "unicorn.conf.erb"
      variables common_variables
    end
    
    template "#{node[:bluepill][:conf_dir]}/#{app_id}.pill" do
      mode 0644
      source "bluepill_unicorn.conf.erb"
      variables common_variables.merge(
        :interval => node[:rails][:monitor_interval],
        :memory_limit => node[:rails][:memory_limit],
        :cpu_limit => node[:rails][:cpu_limit])
    end
    
    bluepill_service app_id do
      action [:enable, :load, :start]
    end
    
    nginx_site app_id do
      action :enable
    end
    
    logrotate app_id do
      files ["/u/apps/#{app_id}/current/log/*.log"]
      frequency "daily"
      rotate_count 14
      compress true
      restart_command "/etc/init.d/nginx reload > /dev/null"
    end
  end
end
