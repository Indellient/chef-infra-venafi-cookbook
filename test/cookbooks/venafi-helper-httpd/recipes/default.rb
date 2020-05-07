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
            :sslcertificate => "/etc/venafi/orange.example.com.cert",
            :sslkey => "/etc/venafi/orange.example.com.key",
            :sslchainfile => "/etc/venafi/orange.example.com.chain"
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