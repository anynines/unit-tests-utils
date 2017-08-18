require 'yaml'

module UnitTestsUtils::InternalDNS
  # <b>DEPRECATED:</b> Please use <tt>resolve_domain_name</tt> instead.
  def self.resolv(hostname)
    warn "[DEPRECATION] `resolv` is deprecated. Please use `resolve_domain_name` instead."
    resolve_domain_name(hostname).first
  end

  def self.resolve_domain_name(hostname)
    `dig +short #{hostname} @#{nameserver_ip}`.strip.split("\n")
  end

  def self.host_addresses(hostnames, port)
    hostnames.map { |hostname| "#{resolv(hostname)}:#{port}" }
  end

  def self.nameserver_ip
    if ENV['INTERNAL_DNS_IP'] then
      ENV['INTERNAL_DNS_IP']
    else
      iaas_config = YAML.load_file(ENV['PATH_TO_IAAS_CONFIG'])
      return iaas_config['iaas']['consul']['dnsmasq_ips'][0]
    end
  end

  def self.valid_hostnames?(hostnames)
    hostnames.all? { |hostname| valid_ips?([resolv(hostname)]) }
  end

  def self.valid_ips?(ip_addresses)
    ip_addresses.all? { |ip| ip =~ /^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$/ }
  end
end
