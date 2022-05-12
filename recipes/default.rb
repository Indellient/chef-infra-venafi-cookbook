#
# Cookbook:: venafi-helper
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

chef_gem 'vcert' do
  action :install
end
