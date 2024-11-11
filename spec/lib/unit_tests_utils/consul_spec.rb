require 'spec_helper'

describe UnitTestsUtils::Consul do
  let(:internal_consul_ip) { '1.2.3.4' }

  before do
    allow(ENV).to receive(:[]).with('INTERNAL_CONSUL_IP')
      .and_return(internal_consul_ip)
  end

  describe '.get_value_for_key' do
    let(:key) { 'key' }
    let(:result) { 'result' }

    it 'curls consul for the given key' do
      expect(described_class).to receive(:`).once
        .with("curl -s http://#{internal_consul_ip}:8500/v1/kv/#{key}?raw")
        .and_return(result)

      expect(described_class.get_value_for_key(key)).to eq result
    end
  end

  describe '.ip_address' do
    it 'returns the env var INTERNAL_CONSUL_IP' do
      expect(described_class.ip_address).to eq internal_consul_ip
    end
  end
end
