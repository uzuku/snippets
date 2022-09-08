require 'etcd'
require 'json'

etcd_address = {
  'yz' => '10.14.15.43',
  'cq' => '10.14.130.92',
  'szth' => '10.12.1.45',
  'gzns' => '10.9.0.51',
  'gzhxy' => '10.9.128.39'
}


cluster = ARGV[0]
org = ARGV[1]
deployment_id = ARGV[2]

if cluster.nil? || org.nil? || deployment_id.nil?
  puts "NOTICE:\nUsage: ruby find_not_finish_deploy_instances.rb ${cluster}(eg: yz, cq, szth, gzns, gzhxy) ${org}(eg: wenkubce) ${deployment_id}"
  exit 0
end

puts "The input params is cluser: #{cluster}  org: #{org}  deployment_id: #{deployment_id}\n"
etcd =Etcd.client(host: etcd_address[cluster], port: '4001')
base = "/jpaas-wing/bce-#{cluster}/#{org}/instances"
data = etcd.get(base, recursive: true).children

all_instances = []
data.each do |item|
  item.children.each do |app|
    app.children.each do |ins|
      info = JSON.parse(ins.value)
      all_instances << info['instance_id']
    end
  end
end


finish_instances = []
etcd.get("/jpaas-wing/bce-#{cluster}/#{org}/deployments/#{deployment_id}").children.each do |n|
  d = etcd.get("#{n.key}/deployment")
  node = JSON.parse(d.value)
  finish_instances<< node['manifest']['instance_id']
end

puts "The instances which has no deployment result is:"
puts all_instances - finish_instances
