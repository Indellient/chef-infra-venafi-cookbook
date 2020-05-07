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

package 'nginx' do
    action :install
end

template "/etc/nginx/nginx.conf" do
     source "nginx.conf.erb"
     variables(
        :sslcertificate => "/etc/venafi/orange.example.com.cert",
        :sslkey => "/etc/venafi/orange.example.com.key",
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