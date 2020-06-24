include_recipe 'venafi-helper::default'

venafihelper node['venafi-helper-tomcat']['common_name'] do
  tpp_username     node['venafi-helper-tomcat']['username']
  tpp_password     node['venafi-helper-tomcat']['password']
  tpp_url          node['venafi-helper-tomcat']['url']
  apikey           node['venafi-helper-tomcat']['apikey']
  zone             node['venafi-helper-tomcat']['zone']
  location         node['venafi-helper-tomcat']['location']
  app_name         node['venafi-helper-tomcat']['app_name']
  app_info         node['venafi-helper-tomcat']['app_info']
  tls_address      node['venafi-helper-tomcat']['tls_address']
  renew_threshold  node['venafi-helper-tomcat']['renew_threshold']
  action :run
end

if platform_family?('rhel')
  package 'epel-release'
end
  
if platform_family?('debian')
  apt_update 'update'
end

package 'tomcat' do
    action :install
end
  
package 'tomcat-native' do
  action :install
end
  
template '/usr/share/tomcat/conf/server.xml' do
  source 'helloworld_server.xml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
      :sslcertificate => "/etc/venafi/#{node['venafi-helper-tomcat']['common_name']}.cert",
      :sslkey => "/etc/venafi/#{node['venafi-helper-tomcat']['common_name']}.key",
  )
end

directory "/usr/share/tomcat/webapps/ROOT/" do
    recursive true
    action :delete
end

remote_directory '/usr/share/tomcat/webapps/ROOT/' do
    source 'public'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
end

directory '/etc/venafi' do
  mode '0755'
  owner 'tomcat'
  group 'tomcat'
end
  
service 'tomcat' do
    action [ :enable, :start ]
end
