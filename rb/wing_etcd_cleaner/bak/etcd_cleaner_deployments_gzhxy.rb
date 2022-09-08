#!/usr/local/bin/ruby
require 'etcd'
require 'json'
require 'yaml'

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

def is_dep_router_failed?(sample_deployment)
  deployment_product = sample_deployment['manifest']['app_group_name']
  deploy_result = sample_deployment['task_status']['current_state']['state']
  return (deployment_product == 'wenku-router' || 
          deployment_product == 'wenku-inrouter-test' || 
          deployment_product == 'wenku-inrouter' || 
          deployment_product == 'wenku-router-test') && deploy_result == 'FAILED'
end

def clean_wing_etcd(cluster)
  etcd_host_ip = @config[cluster]['ip']
  if etcd_host_ip.nil?
    puts "cannot find etcd host ip in #{cluster}"
    return
  end
  delivery_ids = []
  clt = Etcd.client(host: etcd_host_ip, port: 4001)
  clt.get("/jpaas-wing/#{cluster}/wenkubce/delivery/").children.each do |node|
    puts "delete #{node.key}"
    begin
      clt.delete(node.key, recursive: true)
      sleep 0.1
    rescue Etcd::KeyNotFound => e
      puts "delete #{node.key} failed. as #{e}"
    end
  end
  
  products = clt.get("/jpaas-wing/#{cluster}/").children
  products.each do |product_node|
    begin
      deployments = clt.get("#{product_node.key}/deployments").children
      deployments.each do |dep_node|
        dep_dir = dep_node.key
        sample_pod = clt.get(dep_dir).children[0]
        sample_deployment = clt.get("#{sample_pod.key}/deployment").value
        begin
          if is_dep_outdated?(JSON.parse(sample_deployment), EXPIRE_DAYS) && dep_dir.include?('/deployments/')
            puts "delete #{dep_dir}"
            clt.delete(dep_dir, recursive: true)
          elsif is_dep_router_failed?(JSON.parse(sample_deployment)) && dep_dir.include?('/deployments/')
            puts "delete router failed deployment: #{JSON.parse(sample_deployment)}"
            clt.delete(dep_dir, recursive: true)
          else
            puts "cannot delete #{dep_dir}"
          end
        rescue Etcd::KeyNotFound => e
          puts "delete #{dep_dir} failed. as #{e}"
        rescue => e
          puts "exception: #{e.message}\n#{e.backtrace.join('\n')}"
          sleep 2
          retry
        end
      end
    rescue Etcd::KeyNotFound => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end
end

def read_config_from_file(filepath)
  return YAML.load_file(filepath)
end


def main
  current_dir = File.dirname(__FILE__)
  @config = read_config_from_file(File.join(current_dir, 'cluster.yml'))
  puts @config
  %w(bce-gzhxy).each do |cluster|
    puts cluster
    clean_wing_etcd(cluster)
  end
end

main
