#!/usr/local/bin/ruby
require 'etcd'

delivery_ids = []
clt = Etcd.client(host: '10.14.130.92', port: 4001)
clt.get("/jpaas-wing/bce-cq/test-org/deployments/").children.each do |node|
  puts "delete #{node.key}"
  begin
    clt.delete(node.key, recursive: true)
    sleep 0.02
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
