#!/usr/local/bin/ruby
require 'etcd'

delivery_ids = []
clt = Etcd.client(host: '10.12.1.49', port: 4001)
products = clt.get("/jpaas-wing/bce-szth/").children
products.each do |product_node|
  product_name = product_node.key
  next if product_name == "/jpaas-wing/szth/wenkubce"
  puts "product: #{product_name}"
  clt.get("#{product_name}/bootstrap/bootstrap").children.each do |node|
    puts node.key
  end
end
