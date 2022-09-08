#!/usr/local/bin/ruby
require 'etcd'

delivery_ids = []
#clt = Etcd.client(host: '10.14.15.41', port: 4001)
clt = Etcd.client(host: '10.9.0.48', port: 4001)
clt.get("/jpaas-wing/bce-gzns/wenkubce/delivery/").children.each do |node|
  puts "delete #{node.key}"
  begin
    clt.delete(node.key, recursive: true)
    sleep 0.1
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
