require 'yaml'

module UnitTestsUtils::Consul
  def self.get_value_for_key(key)
    `curl -s http://#{ip_address}:8500/v1/kv/#{key}?raw`
  end

  def self.ip_address
    if ENV['INTERNAL_CONSUL_IP'] then
      return ENV['INTERNAL_CONSUL_IP']
    else
      iaas_config = YAML.load_file(ENV['PATH_TO_IAAS_CONFIG'])
      return iaas_config['iaas']['consul']['consul_ips'][0]
    end

    raise 'No consul ip found'
  end
end
