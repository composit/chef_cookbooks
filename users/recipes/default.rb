include_recipe 'ruby-shadow'
package 'zsh'

node[:groups].each do |group|
  group group[:name] do
    group_name group[:name]
    action [ :create, :modify, :manage ]
  end

  group[:users].each do |user|
    home_dir = "/home/#{user[:name]}"

    group user[:name]

    user user[:name] do
      gid group[:name]
      home home_dir
      shell "/bin/zsh"
      password user[:password]
      supports :manage_home => true
      action [:create, :manage]
    end
    
    directory "#{home_dir}" do
      owner user[:name]
      group user[:name]
      mode 0700
      recursive true
    end

    directory "#{home_dir}/.ssh" do
      action :create
      owner user[:name]
      group user[:name]
      mode 0700
    end

    template "#{home_dir}/.ssh/authorized_keys" do
      source "authorized_keys.erb"
      action :create
      owner user[:name]
      group user[:name]
      variables(:keys => user[:ssh_keys])
      mode 0600
    end

    template "/etc/sudoers.d/app" do
      owner "root"
      group "root"
      action :create
      variables( :user => user[:name] )
      mode 0440
    end
  end
end

template "/root/.profile" do
  owner "root"
  group "root"
  mode "0600"
  source '.profile'
end
