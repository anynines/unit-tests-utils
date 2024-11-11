require 'spec_helper'

describe UnitTestsUtils::InternalDNS do
  let(:internal_dns_ip) { '1.2.3.4' }
  let(:hostname1) { 'hostname1.domain' }
  let(:hostname2) { 'hostname2.domain' }
  let(:hostname3) { 'hostname3.domain' }
  let(:ip1) { '2.3.4.5' }
  let(:ip2) { '3.4.5.6' }
  let(:ip3) { '4.5.6.7' }

  before do
    allow(ENV).to receive(:[]).with('INTERNAL_DNS_IP')
      .and_return(internal_dns_ip)
  end

  describe '.resolv' do
    before do
      allow(described_class)
        .to receive(:resolve_domain_name)
        .with(hostname1)
        .and_return([ip1, ip2, ip3])
      allow(described_class)
        .to receive(:resolve_domain_name)
        .with(hostname2)
        .and_return([ip1])
      allow(described_class)
        .to receive(:resolve_domain_name)
        .with(hostname3)
        .and_return([])
    end

    it 'digs the first ip and strips the result' do
      expect(described_class.resolv(hostname1)).to eq ip1
      expect(described_class.resolv(hostname2)).to eq ip1
      expect(described_class.resolv(hostname3)).to be_nil
    end
  end

  describe '.resolve_domain_name' do
    before do
      expect(described_class)
        .to receive(:`)
        .with("dig +short #{hostname1} @#{internal_dns_ip}")
        .and_return("#{ip1}\n#{ip2}\n#{ip3}\n")
      expect(described_class)
        .to receive(:`)
        .with("dig +short #{hostname2} @#{internal_dns_ip}")
        .and_return("#{ip1}\n")
      expect(described_class)
        .to receive(:`)
        .with("dig +short #{hostname3} @#{internal_dns_ip}")
        .and_return('')
    end

    it 'digs the ip, strips the result and split it into an array with one position per returned ip' do
      expect(described_class.resolve_domain_name(hostname1)).to eq [ip1, ip2, ip3]
      expect(described_class.resolve_domain_name(hostname2)).to eq [ip1]
      expect(described_class.resolve_domain_name(hostname3)).to eq []
    end
  end

  describe '.host_adresses' do
    let(:port) { '1234' }

    before do
      allow(described_class)
        .to receive('resolve_domain_name')
        .with(hostname1)
        .and_return([ip1, ip2])
      allow(described_class)
        .to receive('resolve_domain_name')
        .with(hostname2)
        .and_return([ip3])
    end

    it 'resolves all hostnames and add the port' do
      expect(described_class.host_addresses([hostname1], port))
        .to eq ["#{ip1}:#{port}", "#{ip2}:#{port}"]
      expect(described_class.host_addresses([hostname2], port))
        .to eq ["#{ip3}:#{port}"]
      expect(described_class.host_addresses([hostname1, hostname2], port))
        .to eq ["#{ip1}:#{port}", "#{ip2}:#{port}", "#{ip3}:#{port}"]
    end
  end

  describe '.nameserver_ip' do
    it 'returns the env var INTERNAL_DNS_IP' do
      expect(described_class.nameserver_ip).to eq internal_dns_ip
    end
  end

  describe '.valid_hostnames?' do
    before do
      allow(described_class)
        .to receive(:resolve_domain_name)
        .with(hostname1)
        .and_return([ip1])
      allow(described_class)
        .to receive(:resolve_domain_name)
        .with(hostname2)
        .and_return([ip2, ip3])
    end

    context 'when the list is invalid' do
      before do
        allow(described_class)
          .to receive(:resolve_domain_name)
          .with(hostname3)
          .and_return([])
      end

      it 'returns false' do
        expect(described_class).not_to be_valid_hostnames([hostname3])
        expect(described_class).not_to be_valid_hostnames([hostname1, hostname3])
        expect(described_class).not_to be_valid_hostnames([hostname2, hostname3])
      end
    end

    context 'when the list is valid' do
      it 'returns true' do
        expect(described_class).to be_valid_hostnames([])
        expect(described_class).to be_valid_hostnames([hostname1])
        expect(described_class).to be_valid_hostnames([hostname2])
        expect(described_class).to be_valid_hostnames([hostname1, hostname2])
      end
    end
  end

  describe '.valid_ips?' do
    context 'when a list is invalid' do
      it 'return false' do
        expect(described_class).not_to be_valid_ips([''])
        expect(described_class).not_to be_valid_ips(['no'])
        expect(described_class).not_to be_valid_ips(['1.2.3'])
        expect(described_class).not_to be_valid_ips(['1.2.3.a'])
        expect(described_class).not_to be_valid_ips(['111.222.333.4444'])
        expect(described_class).not_to be_valid_ips(['1a2b3c4'])
        expect(described_class).not_to be_valid_ips([ip1, ''])
      end
    end

    context 'when a list is valid' do
      it 'return true' do
        expect(described_class).to be_valid_ips([])
        expect(described_class).to be_valid_ips([ip1])
        expect(described_class).to be_valid_ips([ip1, ip2, ip3])
      end
    end
  end
end
