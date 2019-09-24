#
# Cookbook:: fingerprinter
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

hab_install 'install habitat' do
  license 'accept'
end

hab_package 'migration/fingerprinter'

hab_sup 'default' do
  license 'accept'
end

directory 'C:/hab/svc/windows-service' do
  recursive true
  only_if platform?('windows')
end

hab_service 'migration/fingerprinter' do
  strategy 'at-once'
  topology 'standalone'
end
