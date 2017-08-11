require 'json'

module UnitTestsUtils::Consul
  def self.get_value_for_key(key)
    `curl -s http://#{ip_address}:8500/v1/kv/#{key}?raw`
  end

  def self.ip_address
    if ENV['INTERNAL_CONSUL_IP'] then
      return ENV['INTERNAL_CONSUL_IP']
    else
      instances = JSON.parse(`bosh vms -d consul-dns --json`)["Tables"][0]["Rows"]

      instances.each_with_index do |val, index| 
        if instances[index]["instance"].match?("consul") then 
          return instances[index]["ips"] 
        end 
      end
    end

    raise 'No consul ip found'
  end
end
