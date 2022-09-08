#!/usr/local/bin/ruby
require 'etcd'
require 'json'
require 'yaml'

#EXPIRE_DAYS = 14

def expire_days(cluster)
  # because the number of instances in yz now is the sum of cq's and earlier yz's
  if cluster == 'bce-yz'
    return 7
  end
  return 14
end

def is_failed?(sample_deployment)
  return sample_deployment['task_status']['current_state']['state'] == 'FAILED'
end

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

def clean_wing_etcd(cluster)
  etcd_host_ip = @config[cluster]['ip']
  if etcd_host_ip.nil?
    puts "cannot find etcd host ip in #{cluster}"
    return
  end
  delivery_ids = []
  clt = Etcd.client(host: etcd_host_ip, port: 4001)
  
  products = clt.get("/jpaas-wing/#{cluster}/").children
  # delete all deliveries
  products.each do |product_node|
    product_name = product_node.key
    clt.get("#{product_name}/delivery/").children.each do |node|
      puts "delete #{node.key}"
      begin
        clt.delete(node.key, recursive: true)
        sleep 0.1
      rescue Etcd::KeyNotFound => e
        puts "delete #{node.key} failed. as #{e}"
      rescue => e
        sleep 2
        retry
      end
    end
  end

  # delete expired deployments
  products.each do |product_node|
    begin
      deployments = clt.get("#{product_node.key}/deployments").children
      deployments.each do |dep_node|
        dep_dir = dep_node.key
        begin
          sample_pod = clt.get(dep_dir).children[0]
          sample_deployment = clt.get("#{sample_pod.key}/deployment").value
          if is_dep_outdated?(JSON.parse(sample_deployment), expire_days(cluster)) && dep_dir.include?('/deployments/')
            puts "delete #{dep_dir}"
            clt.delete(dep_dir, recursive: true)
          elsif is_failed?(JSON.parse(sample_deployment)) && dep_dir.include?('/deployments/')
            puts "delete #{dep_dir} as deploy failed"
            clt.delete(dep_dir, recursive: true)
          else
            puts "cannot delete #{dep_dir}"
          end
        rescue Etcd::KeyNotFound => e
          puts "delete #{dep_dir} failed. as #{e}"
          next
        rescue => e
          puts "exception: #{e.message}\n#{e.backtrace.join('\n')}"
          sleep 2
          #retry
        end
      end
    rescue Etcd::KeyNotFound => e
      puts e.message
      puts e.backtrace.join("\n")
      next
    end
  end

  # delete expired executions
  products.each do |product_node|
    begin
      # commit that some products have no executions yet.
      begin
        executions = clt.get("#{product_node.key}/executions").children
      rescue Etcd::KeyNotFound => e
        puts "product #{product_node.key} has no executions yet"
        next
      end
      executions.each do |exec_node|
        exec_dir = exec_node.key
        begin
          sample_pod = clt.get(exec_dir).children[0]
          sample_execution = clt.get("#{sample_pod.key}/execution").value
          if is_dep_outdated?(JSON.parse(sample_execution), expire_days(cluster)) && exec_dir.include?('/executions/')
            puts "delete #{exec_dir}"
            clt.delete(exec_dir, recursive: true)
          else
            puts "cannot delete #{exec_dir}"
          end
        rescue Etcd::KeyNotFound => e
          puts "delete #{exec_dir} failed. as #{e}"
          next
        rescue => e
          puts "exception: #{e.message}\n#{e.backtrace.join('\n')}"
          sleep 2
          #retry
        end
      end
    rescue Etcd::KeyNotFound => e
      puts e.message
      puts e.backtrace.join("\n")
      next
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
  %w(bce-yz bce-szth bce-gzns bce-hb bce-cq).each do |cluster|
    puts cluster
    puts @config[cluster]['ip']
    clean_wing_etcd(cluster)
  end
end

main
