include_recipe 'venafi-helper::default'

venafihelper node['venafi-helper-nginx']['common_name'] do
  tpp_username     node['venafi-helper-nginx']['username']
  tpp_password     node['venafi-helper-nginx']['password']
  token            node['venafi-helper-nginx']['token']
  tpp_url          node['venafi-helper-nginx']['url']
  apikey           node['venafi-helper-nginx']['apikey']
  zone             node['venafi-helper-nginx']['zone']
  location         node['venafi-helper-nginx']['location']
  app_name         node['venafi-helper-nginx']['app_name']
  tls_address      node['venafi-helper-nginx']['tls_address']
  renew_threshold  node['venafi-helper-nginx']['renew_threshold']
  action :run
end

if platform_family?('rhel')
  package 'epel-release'
end

if platform_family?('debian')
  apt_update 'update'
end

package 'nginx' do
    action :install
end

template "/etc/nginx/nginx.conf" do
     source "nginx.conf.erb"
     variables(
      :sslcertificate => "/etc/venafi/#{node['venafi-helper-nginx']['common_name']}.cert",
      :sslkey => "/etc/venafi/#{node['venafi-helper-nginx']['common_name']}.key",
     )
end

directory "usr/share/nginx/html/" do
    recursive true
    action :delete
end

remote_directory 'usr/share/nginx/html/' do
    source 'public'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
end

service 'nginx' do
    action [ :enable, :start ]
end
