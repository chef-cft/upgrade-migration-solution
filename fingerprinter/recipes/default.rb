#
# Cookbook:: fingerprinter
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.

hab_install 'install habitat' do
  license 'accept'
  if platform?('windows')
    not_if 'Get-Command hab'
  else
    not_if 'which hab'
  end
end

hab_package 'migration/fingerprinter'

directory 'C:/hab/svc/windows-service' do
  recursive true
  only_if { platform?('windows') }
end

hab_sup 'default' do
  license 'accept'
  not_if { platform?('windows') && ::Win32::Service.exists?('Habitat') }
end

hab_service 'migration/fingerprinter' do
  strategy 'at-once'
  topology 'standalone'
end
