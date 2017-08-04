require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::InternalDNS do
  let(:internal_dns_ip) { "1.2.3.4" }

  before :each do
    allow(ENV).to receive(:[]).with("INTERNAL_DNS_IP").
      and_return(internal_dns_ip)
  end

  describe ".resolv" do
    let(:hostname) { "hostname.domain" }
    let(:ip) { "2.3.4.5" }

    it "digs the ip and strips the result" do
      expect(UnitTestsUtils::InternalDNS).
        to receive(:`).
        with("dig +short #{hostname} @#{internal_dns_ip}").
        and_return(ip + "\n")

      expect(UnitTestsUtils::InternalDNS.resolv(hostname)).to eq ip
    end
  end

  describe ".host_adresses" do
    let(:port) { "1234" }
    let(:hostname1) { "hostname1.domain" }
    let(:hostname2) { "hostname2.domain" }
    let(:ip1) { "3.4.5.6" }
    let(:ip2) { "4.5.6.7" }

    it "resolvs all hostname and add ports" do
      expect(UnitTestsUtils::InternalDNS).
        to receive("resolv").with(hostname1).and_return(ip1)
      expect(UnitTestsUtils::InternalDNS).
        to receive("resolv").with(hostname2).and_return(ip2)

      expect(UnitTestsUtils::InternalDNS.host_addresses([hostname1, hostname2], port)).
        to eq ["#{ip1}:#{port}", "#{ip2}:#{port}"]
    end
  end

  describe ".nameserver_ip" do
    it "returns the env var INTERNAL_DNS_IP" do
      expect(UnitTestsUtils::InternalDNS.nameserver_ip).to eq internal_dns_ip
    end
  end

  describe ".valid_hostnames?" do
    let(:hostname1) { "hostname1.domain" }
    let(:hostname2) { "hostname2.domain" }
    before :each do
      allow(UnitTestsUtils::InternalDNS).
        to receive(:resolv).with(hostname1).and_return("1.2.3.4")
    end

    context "when the list is invalid" do
      before :each do
        allow(UnitTestsUtils::InternalDNS).
          to receive(:resolv).with(hostname2).and_return("no")
      end

      it "returns false" do
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname1, hostname2])).
          to be_falsey
      end
    end

    context "when the list is valid" do
      before :each do
        allow(UnitTestsUtils::InternalDNS).
          to receive(:resolv).with(hostname2).and_return("2.3.4.5")
      end
            it "returns true" do
        expect(UnitTestsUtils::InternalDNS.valid_hostnames?([hostname1, hostname2])).
          to be_truthy
      end
    end
  end

  describe ".valid_ips?" do
    context " when a list is invalid" do
      let(:invalid_list) { ["1.2.3.4", "no"] }
      it "return false" do
        expect(UnitTestsUtils::InternalDNS.valid_ips?(invalid_list)).to be_falsey
      end
    end

    context "when a list is valid" do
      let(:valid_list) { ["1.2.3.4", "111.222.333.444"] }
      it "return true" do
        expect(UnitTestsUtils::InternalDNS.valid_ips?(valid_list)).to be_truthy
      end
    end
  end
end


