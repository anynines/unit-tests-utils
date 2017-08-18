require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::Consul do
  let(:internal_consul_ip) { "1.2.3.4" }
  let(:bosh_consul_ips) { ["10.244.6.15", "10.244.5.15", "10.244.7.15"] }
  let(:json_path) { File.dirname(__FILE__) + "/../../fixtures/consul_dns_example.json" }
  let(:path_iaas_config) { File.dirname(__FILE__) + "/../../fixtures/sample_iaas_config.yml" }

  describe ".get_value_for_key" do
    let(:key) { "key" }
    let(:result) { "result" }

    before(:each) do
      allow(ENV).to receive(:[]).with("INTERNAL_CONSUL_IP").
      and_return(internal_consul_ip)
    end

    it "curls consul for the given key" do
      expect(UnitTestsUtils::Consul).to receive(:`).once.
        with("curl -s http://#{internal_consul_ip}:8500/v1/kv/#{key}?raw").
        and_return(result)

      expect(UnitTestsUtils::Consul.get_value_for_key(key)).to eq result
    end
  end

  describe ".ip_address" do
    context "when a INTERNAL_CONSUL_IP env variable is set" do
      before(:each) do
        allow(ENV).to receive(:[]).with("INTERNAL_CONSUL_IP").
        and_return(internal_consul_ip)
      end

      it "returns a valid consul ip address" do
        expect(UnitTestsUtils::Consul.ip_address).to eq internal_consul_ip
      end
    end

    context "when no INTERNAL_CONSUL_IP env variable is set" do
      before(:each) do
        allow(ENV).to receive(:[]).with("INTERNAL_CONSUL_IP").
        and_return(nil)
      end

      before(:each) do
        allow(ENV).to receive(:[]).with("PATH_TO_IAAS_CONFIG").
          and_return(path_iaas_config)
      end

      it "returns a valid consul ip address" do
        expect(bosh_consul_ips).to include UnitTestsUtils::Consul.ip_address
      end
    end
  end
end

