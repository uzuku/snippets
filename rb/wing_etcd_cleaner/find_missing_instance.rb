#!/usr/local/bin/ruby
require 'etcd'
require 'json'

args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]

cluster = args['c']
etcd_host_map = {
  'gzns' => '10.9.0.51',
  'yz' => '10.14.15.45',
  'cq' => '10.14.130.92',
  'gzhxy' => '10.9.128.39',
  'szth' => '10.12.1.45'
}

etcd_host = etcd_host_map[cluster]
if etcd_host.nil?
  puts "usage: ./find_missing_instance.rb -c=gzns/yz/cq/gzhxy/szth --id={deployment_id}"
  raise "cluster not found"
end

deployment_id = args['id']

clt = Etcd.client(host: etcd_host, port: 4001)
clt.get("/jpaas-wing/bce-#{cluster}/wenkubce/deployments/#{deployment_id}").children.each do |n|
  puts n.key
  d = clt.get("#{n.key}/deployment")
  node = JSON.parse(d.value)
  if node != nil
    if node['task_status']['current_state']['state'] != 'SUCCESS'
      puts "not running: instance_id #{node['manifest']['instance_id']} container_id #{node['manifest']['container_id']} host_ip #{node['manifest']['host_ip']}"
    end
  end
end
