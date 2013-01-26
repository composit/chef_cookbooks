include_recipe "users"

["/u", "/u/apps"].each do |dir|
  directory dir do
    owner "app"
    group "app"
    mode 0755
  end
end

if node[:active_applications]
  node[:active_applications].each do |name, conf|
    %w(config tmp sockets log pids system bin).each do |dir|
      # can't assign user and group recursively
      directory "/u/apps/#{name}" do
        owner "app"
        group "app"
      end

      directory "/u/apps/#{name}/releases" do
        owner "app"
        group "app"
      end

      directory "/u/apps/#{name}/shared" do
        owner "app"
        group "app"
      end

      directory "/u/apps/#{name}/shared/#{dir}" do
        recursive true
        owner "app"
        group "app"
      end
    end

    if conf[:conf_variables]
      template "/u/apps/#{name}/shared/config/application.yml" do
        variables :conf_variables => conf[:conf_variables]
        owner "app"
        group "app"
      end
    end

    if conf[:databases]
      template "/u/apps/#{name}/shared/config/database.yml" do
        variables :app_name => name, :databases => conf[:databases]
        owner "app"
        group "app"
      end

      conf[:databases].each do |env, db_conf|
        if db_conf[:adapter] == 'postgresql'
          #package 'postgresql-client-common'

          execute "create-database-user" do
            exists = <<-EOH
            sudo -u postgres psql -c "select rolname from pg_roles" | grep app
            EOH
            command <<-EOH
            sudo -u postgres psql -c "create role app with LOGIN"
            EOH
            not_if exists
          end

          execute "create-database" do
            db_name = "#{name}_#{conf[:env]}"
            exists = <<-EOH
            sudo -u postgres psql -c "select * from pg_database WHERE datname='#{db_name}'" | grep -c #{db_name}
            EOH
            command "sudo -u postgres createdb -O app -E utf8 #{db_name}"
            not_if exists
          end
        elsif db_conf[:adapter] == 'mysql2'
          execute "create-database" do
            db_name = "#{name}_#{conf[:env]}"
            exists = <<-EOH
            mysql -u root -p#{node[:mysql][:root_password]} -e "show databases;" | grep #{db_name}
            EOH
            command <<-EOH
            mysql -u root -p#{node[:mysql][:root_password]} -e "create database #{db_name}"
            mysql -u root -p#{node[:mysql][:root_password]} -e "grant all on #{db_name}.* to '#{db_conf[:username]}'@'localhost' identified by '#{db_conf[:password]}'"
            EOH
            not_if exists
          end
        end
      end
    end
            
    if conf[:packages]
      conf[:packages].each do |package_name|
        package package_name
      end      
    end

    if conf[:gems]
      conf[:gems].each do |g|
        if g.is_a? Array
          gem_package g.first do
            version g.last
          end
        else
          gem_package g
        end
      end
    end
  
    if conf[:symlinks]
      conf[:symlinks].each do |target, source|
        link target do
          to source
        end
      end
    end
  end
end
