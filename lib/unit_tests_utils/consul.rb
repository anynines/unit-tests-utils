module UnitTestsUtils::Consul
  def self.get_value_for_key(key)
    `curl -s http://#{ip_address}:8500/v1/kv/#{key}?raw`
  end

  def self.ip_address
    ENV['INTERNAL_CONSUL_IP']
  end

  def self.deregister_master_alias(master_alias)
    consul_endpoint = "http://#{ENV['INTERNAL_CONSUL_IP']}:8500/v1/catalog/deregister"
    payload = "{ \"node\": \"#{master_alias}\" }"

    http_code = `curl -s -S -w %{http_code} -o /dev/null --connect-timeout 15 -X PUT -d '#{payload}' #{consul_endpoint}`

    if "#{http_code}" != "200"
      raise ("could not deregister master alias: #{http_code} payload: #{payload}, endpoint: #{consul_endpoint}")
    end
    return true
  end
end
