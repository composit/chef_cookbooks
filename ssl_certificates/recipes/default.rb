directory node[:ssl_certificates][:path] do
  mode "0750"
  owner "root"
  group "www-data"
end

if node[:ssl_certificates] && node[:ssl_certificates][:sites]
  node[:ssl_certificates][:sites].each do |name, data|
    template "#{node[:ssl_certificates][:path]}/#{name}.key" do
      source "cert.erb"
      mode "0644"
      owner "root"
      group "www-data"
      variables :cert => data["key"]
    end

    template "#{node[:ssl_certificates][:path]}/#{name}.pem" do
      source "cert.erb"
      mode "0644"
      owner "root"
      group "www-data"
      variables :cert => data["pem"]
    end
  end
end
