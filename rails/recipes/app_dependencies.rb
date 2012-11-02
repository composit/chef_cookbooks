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
    %w(config tmp sockets log tmp/pids system bin).each do |dir|
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
