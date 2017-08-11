require 'json'

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
      return ENV['INTERNAL_DNS_IP']
    else
      instances = JSON.parse(`bosh vms -d consul-dns --json`)["Tables"][0]["Rows"]
      
      instances.each_with_index do |val, index| 
        if instances[index]["instance"].match?("dnsmasq") then 
          return instances[index]["ips"] 
        end 
      end
    end

    raise 'No internal dns ip found'
  end

  def self.valid_hostnames?(hostnames)
    hostnames.all? { |hostname| valid_ips?([resolv(hostname)]) }
  end

  def self.valid_ips?(ip_addresses)
    ip_addresses.all? { |ip| ip =~ /^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$/ }
  end
end
