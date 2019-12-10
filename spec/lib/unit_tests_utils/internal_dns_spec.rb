require 'spec_helper'

describe UnitTestsUtils::InternalDNS do
  let(:internal_dns_ip) { "1.2.3.4" }
  let(:hostname1) { "hostname1.domain" }
  let(:hostname2) { "hostname2.domain" }
  let(:hostname3) { "hostname3.domain" }
  let(:ip1) { "2.3.4.5" }
  let(:ip2) { "3.4.5.6" }
  let(:ip3) { "4.5.6.7" }

  before :each do
    allow(ENV).to receive(:[]).with("INTERNAL_DNS_IP").
      and_return(internal_dns_ip)
  end

  describe ".resolv" do
    before(:example) do
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolve_domain_name).
        with(hostname1).
        and_return([ip1, ip2, ip3])
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolve_domain_name).
        with(hostname2).
        and_return([ip1])
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolve_domain_name).
        with(hostname3).
        and_return([])
    end

    it "digs the first ip and strips the result" do
      expect(UnitTestsUtils::InternalDNS.resolv(hostname1)).to eq ip1
      expect(UnitTestsUtils::InternalDNS.resolv(hostname2)).to eq ip1
      expect(UnitTestsUtils::InternalDNS.resolv(hostname3)).to be_nil
    end
  end

  describe ".resolve_domain_name" do
    before(:example) do
      expect(UnitTestsUtils::InternalDNS).
        to receive(:`).
        with("dig +short #{hostname1} @#{internal_dns_ip}").
        and_return("#{ip1}\n#{ip2}\n#{ip3}\n")
      expect(UnitTestsUtils::InternalDNS).
        to receive(:`).
        with("dig +short #{hostname2} @#{internal_dns_ip}").
        and_return("#{ip1}\n")
      expect(UnitTestsUtils::InternalDNS).
        to receive(:`).
        with("dig +short #{hostname3} @#{internal_dns_ip}").
        and_return('')
    end

    it "digs the ip, strips the result and split it into an array with one position per returned ip" do
      expect(UnitTestsUtils::InternalDNS.resolve_domain_name(hostname1)).to eq [ip1, ip2, ip3]
      expect(UnitTestsUtils::InternalDNS.resolve_domain_name(hostname2)).to eq [ip1]
      expect(UnitTestsUtils::InternalDNS.resolve_domain_name(hostname3)).to eq []
    end
  end

  describe ".host_adresses" do
    let(:port) { "1234" }

    before(:example) do
      allow(UnitTestsUtils::InternalDNS).
        to receive("resolve_domain_name").
        with(hostname1).
        and_return([ip1, ip2])
      allow(UnitTestsUtils::InternalDNS).
        to receive("resolve_domain_name").
        with(hostname2).
        and_return([ip3])
    end

    it "resolves all hostnames and add the port" do
      expect(UnitTestsUtils::InternalDNS.host_addresses([hostname1], port)).
        to eq ["#{ip1}:#{port}", "#{ip2}:#{port}"]
      expect(UnitTestsUtils::InternalDNS.host_addresses([hostname2], port)).
        to eq ["#{ip3}:#{port}"]
      expect(UnitTestsUtils::InternalDNS.host_addresses([hostname1, hostname2], port)).
        to eq ["#{ip1}:#{port}", "#{ip2}:#{port}", "#{ip3}:#{port}"]
    end
  end

  describe ".nameserver_ip" do
    it "returns the env var INTERNAL_DNS_IP" do
      expect(UnitTestsUtils::InternalDNS.nameserver_ip).to eq internal_dns_ip
    end
  end

  describe ".valid_hostnames?" do
    before(:example) do
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolve_domain_name).
        with(hostname1).
        and_return([ip1])
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolve_domain_name).
        with(hostname2).
        and_return([ip2, ip3])
    end

    context "when the list is invalid" do
      before(:example) do
        allow(UnitTestsUtils::InternalDNS).
          to receive(:resolve_domain_name).
          with(hostname3).
          and_return([])
      end

      it "returns false" do
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname3])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname1, hostname3])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname2, hostname3])).to be_falsey
      end
    end

    context "when the list is valid" do
      it "returns true" do
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([])).to be_truthy
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname1])).to be_truthy
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname2])).to be_truthy
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname1, hostname2])).to be_truthy
      end
    end
  end

  describe ".valid_ips?" do
    context " when a list is invalid" do
      it "return false" do
        expect(UnitTestsUtils::InternalDNS.valid_ips?([""])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?(["no"])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?(["1.2.3"])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?(["1.2.3.a"])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?(["111.222.333.4444"])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?(["1a2b3c4"])).to be_falsey
        expect(UnitTestsUtils::InternalDNS.valid_ips?([ip1, ""])).to be_falsey
      end
    end

    context "when a list is valid" do
      it "return true" do
        expect(UnitTestsUtils::InternalDNS.valid_ips?([])).to be_truthy
        expect(UnitTestsUtils::InternalDNS.valid_ips?([ip1])).to be_truthy
        expect(UnitTestsUtils::InternalDNS.valid_ips?([ip1, ip2, ip3])).to be_truthy
      end
    end
  end
end
