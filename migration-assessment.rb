#!/c/opscode/chefdk/embedded/bin/ruby

require 'chef'

def determine_knife_loc
  return ARGV[0] unless ARGV.empty?
  return "#{ENV['HOME']}/.chef/knife.rb" if ARGV.empty?
end

Chef::Config.from_file(determine_knife_loc)
rest = Chef::ServerAPI.new(Chef::Config[:chef_server_url])
nodes = Chef::Search::Query.new(Chef::Config[:chef_server_url]).search(:node, '*:*', rows: 5000, :filter_result => { 'version' => ['chef_packages','chef', 'version'], 'os' => ['platform'], 'os_version' =>['platform_version']} ).first

version_list = []
nodes.each do  |k|
  version_list << k['version']
end
version_list = version_list.uniq.sort_by{ |i| [i ? 1:0, i]}

nodes_arr = {}
version_list.each do |version|
  count = {}
  nodes.each do |node_data|
    fq_os = "#{node_data['os']}_#{node_data['os_version']}" unless node_data['os'].nil?
    fq_os = 'nil' if node_data['os'].nil?
    if node_data['version'] == version
      if count[fq_os]
        count[fq_os] += 1
      else
        count[fq_os] = 1
      end
    end
  end
  nodes_arr[version] = count
end

puts "\nVersion: Count"
nodes_arr.each do | k, v|
  puts "#{k}: #{v}" unless k.nil?
  puts "nil: #{v}" if k.nil?
end