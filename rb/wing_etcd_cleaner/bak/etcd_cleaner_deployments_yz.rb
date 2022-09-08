#!/usr/local/bin/ruby
require 'etcd'
require 'json'

EXPIRE_DAYS = 30

def is_dep_outdated?(sample_deployment, expire=30)
  deployment_time = sample_deployment['task_status']['current_state']['timestamp']
  dtime = Time.parse(deployment_time)
  etime = Time.parse (Date.today - expire).to_s
  if etime > dtime
    #puts "deploy_time#{dtime}, expired_time#{etime}. outdated" 
    return true
  else
    #puts "deploy_time#{dtime}, expired_time#{etime}. not outdated" 
    return false
  end
end

def is_failed?(sample_deployment)
  return sample_deployment['task_status']['current_state']['state'] == 'FAILED'
end

delivery_ids = []
#clt = Etcd.client(host: '10.14.15.41', port: 4001)
clt = Etcd.client(host: '10.14.15.43', port: 4001)
products = clt.get("/jpaas-wing/bce-yz/").children
products.each do |product_node|
  deployments = clt.get("#{product_node.key}/deployments").children
  deployments.each do |dep_node|
    dep_dir = dep_node.key
    sample_pod = clt.get(dep_dir).children[0]
    sample_deployment = clt.get("#{sample_pod.key}/deployment").value
    begin
      if is_dep_outdated?(JSON.parse(sample_deployment), EXPIRE_DAYS) && dep_dir.include?('/deployments/')
        puts "delete #{dep_dir}"
        clt.delete(dep_dir, recursive: true)
      else
        puts "cannot delete #{dep_dir}"
      end
    rescue Etcd::KeyNotFound => e
      puts "delete #{dep_dir} failed. as #{e}"
    end
  end
end


=begin
clt.get("/jpaas-wing/bce-yz/wenkubce/delivery/").children.each do |node|
  puts "delete #{node.key}"
  begin
    clt.delete(node.key, recursive: true)
    sleep 0.1
  rescue Etcd::KeyNotFound => e
    puts "delete #{node.key} failed. as #{e}"
  end
end
=end
