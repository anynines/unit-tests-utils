module UnitTestsUtils::Consul
  def self.get_value_for_key(key)
    `curl -s http://#{ip_address}:8500/v1/kv/#{key}?raw`
  end

  def self.ip_address
    ENV['INTERNAL_CONSUL_IP']
  end
end
