#!/usr/bin/env ruby

require "net/http"
require "json"

uri = URI("https://supermarket.chef.io/universe")
response = Net::HTTP.get(uri)
urls = []
JSON.parse(response).each do |cb|
  urls << cb[1].sort.last[1]["download_url"]
end

urls.each do |url|
  `wget -O cookbook.tgz #{url}`
  `tar -xzf cookbook.tgz`
end

`rm cookbook.tgz`
