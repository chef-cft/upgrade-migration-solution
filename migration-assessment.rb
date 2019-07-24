#!/c/opscode/chefdk/embedded/bin/ruby.exe

# require 'json'

# json_file = File.read('dump.json')

# nodes_list = JSON.parse(json_file)['rows']

# version_list = []

# nodes_list.each do |node|
#   node.each do |_fqdn, attributes|
#     version_list << attributes['chef_packages.chef.version']
#   end
# end

# version_count = {}

# version_list.each do |version_number|
#   count = {}
#   nodes_list.each do |node|
#     node.each do |_fqdn, attributes|
#       if attributes['chef_packages.chef.version'] == version_number
#         count[attributes['platform_family']] = count[attributes['platform_family']] += 1 if count[attributes['platform_family']]
#         count[attributes['platform_family']] = 1 unless count[attributes['platform_family']]
#       end
#     end
#   end
#   version_count[version_number] = count
# end
# puts "\n\n\n#{version_count}"

#!/c/opscode/chefdk/embedded/bin/ruby

require 'chef'

Chef::Config.from_file("c:/Users/conobcu/.chef/knife.rb")
rest = Chef::ServerAPI.new(Chef::Config[:chef_server_url])
# 'name' => ['name']
nodes = Chef::Search::Query.new(Chef::Config[:chef_server_url]).search(:node, '*:*', rows: 5000, :filter_result => { 'version' => ['chef_packages','chef', 'version']} ).first

nodes_arr = nodes.flat_map{ |ver| ver.values }
counts = Hash.new(0)

nodes_arr.each { |node| counts[node] +=1 }
total_count = 0
counts.each do | _ver, count|
  total_count += count
end

puts counts
puts "\n\n\n Total count: #{total_count}"