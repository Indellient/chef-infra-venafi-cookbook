include_recipe 'venafi-helper::default'

venafihelper 'https://082719192.dev.lab.venafi.com' do
    tpp_username 'username'
    tpp_password 'password'
    policyname   'policyname'
    commonname   'commoname'
    location     '/etc/venafi'
    devicename   'devicename'  
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
    :sslcertificate => "/etc/venafi/orange.example.com.cert",
    :sslkey => "/etc/venafi/orange.example.com.key",
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