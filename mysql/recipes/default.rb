case node['platform']
when 'centos', 'redhat', 'scientific', 'amazon', 'fedora', 'oracle'
  %(mysql-server mysql mysql-devel).each do |pkg|
    package pkg
  end
when 'ubuntu', 'debian'
  %w(mysql-server mysql-client libmysql-ruby libmysqlclient-dev).each do |pkg|
    package pkg
  end
else
  raise 'you are on some sort of different os'
end

bash "secure database" do
  code "mysqladmin -u root password #{node[:mysql][:root_password]}" unless system( "mysql --version | grep Ver" )
end
