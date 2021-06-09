include_recipe 'venafi-helper::default'

venafihelper node['venafi-helper-httpd']['common_name'] do
  tpp_username     node['venafi-helper-httpd']['username']
  tpp_password     node['venafi-helper-httpd']['password']
  token            node['venafi-helper-httpd']['token']
  tpp_url          node['venafi-helper-httpd']['url']
  apikey           node['venafi-helper-httpd']['apikey']
  zone             node['venafi-helper-httpd']['zone']
  location         node['venafi-helper-httpd']['location']
  app_name         node['venafi-helper-httpd']['app_name']
  app_info         node['venafi-helper-httpd']['app_info']
  tls_address      node['venafi-helper-httpd']['tls_address']
  renew_threshold  node['venafi-helper-httpd']['renew_threshold']
  action :run
end

package "httpd" do
  action [:install]
end

package "mod_ssl" do
  action [:install]
end

remote_directory '/var/www/html/' do
  source 'public'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template "/etc/httpd/conf.d/ssl.conf" do
  source "ssl.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables(
      :sslcertificate => "/etc/venafi/#{node['venafi-helper-httpd']['common_name']}.cert",
      :sslkey => "/etc/venafi/#{node['venafi-helper-httpd']['common_name']}.key",
      :sslchainfile => "/etc/venafi/#{node['venafi-helper-httpd']['common_name']}.chain"
      # :servername => "orange.example.com"
  )
end

# change selinux security context for ssl certificates
execute "change_for_selinux" do
  command "chcon -Rv --type=httpd_sys_content_t /etc/venafi/"
  action :run
end

service "httpd" do
  action [:enable,:start]
end
