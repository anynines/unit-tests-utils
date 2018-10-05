module UnitTestsUtils::InternalDNS
  # <b>DEPRECATED:</b> Please use <tt>resolve_domain_name</tt> instead.
  def self.resolv(hostname)
    warn "[DEPRECATION] `resolv` is deprecated. Please use `resolve_domain_name` instead."
    resolve_domain_name(hostname).first
  end

  def self.resolve_domain_name(hostname)
    if self.valid_ips?([hostname])
      return [hostname]
    end

    return `dig +short #{hostname} @#{nameserver_ip}`.strip.split("\n")
  end

  def self.host_addresses(hostnames, port)
    hostnames.map { |hostname| resolve_domain_name(hostname).map { |ip_address| "#{ip_address}:#{port}" } }.flatten
  end

  def self.nameserver_ip
    ENV['INTERNAL_DNS_IP']
  end

  def self.valid_hostnames?(hostnames)
    hostnames.all? do |hostname|
      ips = resolve_domain_name(hostname)

      if ips.empty?
        false
      else
        valid_ips?(ips)
      end
    end
  end

  def self.valid_ips?(ip_addresses)
    ip_addresses.all? { |ip| ip =~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ }
  end
end
