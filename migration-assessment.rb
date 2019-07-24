#!/c/opscode/chefdk/embedded/bin/ruby.exe

require 'json'

json_file = File.read('dump.json')

nodes_list = JSON.parse(json_file)['rows']

version_list = []

nodes_list.each do |node|
  node.each do |_fqdn, attributes|
    version_list << attributes['chef_packages.chef.version']
  end
end

version_count = {}

version_list.each do |version_number|
  count = {}
  nodes_list.each do |node|
    node.each do |_fqdn, attributes|
      if attributes['chef_packages.chef.version'] == version_number
        count[attributes['platform_family']] = count[attributes['platform_family']] += 1 if count[attributes['platform_family']]
        count[attributes['platform_family']] = 1 unless count[attributes['platform_family']]
      end
    end
  end
  version_count[version_number] = count
end
puts "\n\n\n#{version_count}"