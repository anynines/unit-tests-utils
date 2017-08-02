module UnitTestsUtils::InternalDNS
  def self.resolv(hostname)
    `dig +short #{hostname} @#{nameserver_ip}`.strip
  end

  def self.host_addresses(hostnames, port)
    hostnames.map { |hostname| "#{resolv(hostname)}:#{port}" }
  end

  def self.nameserver_ip
    ENV['INTERNAL_DNS_IP']
  end

  def self.valid_hostnames?(hostnames)
  	hostnames.all? { |hostname| valid_ips?([resolv(hostname)]) }
  end

  def self.valid_ips?(ip_addresses)
  	ip_addresses.all? { |ip| ip =~ /^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$/ }
  end
end
