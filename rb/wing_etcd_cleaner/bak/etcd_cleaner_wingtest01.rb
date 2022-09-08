#!/usr/local/bin/ruby
require 'etcd'

delivery_ids = []

clt = Etcd.client(host: '10.199.177.47', port: 4001)
clt.get("/jpaas-wing/wingtest01").children.each do |node|
  dir = "#{node.key}/delivery"
  puts "delete #{dir}"
  begin
    clt.delete(dir, recursive: true)
    sleep 0.1
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
clt.get("/jpaas-wing/wingtest01", port: 4001).children.each do |node|
  dir = "#{node.key}/executions"
  puts "delete #{dir}"
  begin
    clt.delete(dir, recursive: true)
    sleep 0.1
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
clt.get("/jpaas-wing/wingtest01", port: 4001).children.each do |node|
  dir = "#{node.key}/deployments"
  puts "delete #{dir}"
  begin
    clt.delete(dir, recursive: true)
    sleep 0.1
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
