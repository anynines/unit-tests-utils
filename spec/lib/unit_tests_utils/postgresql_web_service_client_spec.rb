require 'spec_helper'

describe UnitTestsUtils::PGWebServiceClient do
  describe '#initialize' do
    subject(:pg_web_service_client) { described_class.new(manifest, pg_web_service_options) }

    let(:manifest_id) { 'manifest_id' }
    let(:manifest) do
      manifest_mocked = double('')
      allow(manifest_mocked).to receive(:name).and_return(manifest_id)
      manifest_mocked
    end

    context 'when there are not options' do
      let(:pg_web_service_options) { {} }

      specify do
        expect(pg_web_service_client.password).to eq UnitTestsUtils::PGWebServiceClient::DEFAULT_WEB_SERVICE_PASSWORD
        expect(pg_web_service_client.manifest_name).to eq manifest_id
      end
    end

    context 'when there are options' do
      let(:manifest_name) { 'manifest_name' }
      let(:password) { UnitTestsUtils::PGWebServiceClient::DEFAULT_WEB_SERVICE_PASSWORD }
      let(:pg_web_service_options) do
        {
          new_manifest_name: manifest_name,
          pg_web_service_password: password
        }
      end

      specify do
        expect(pg_web_service_client.password).to eq password
        expect(pg_web_service_client.manifest_name).to eq manifest_name
      end
    end
  end
end
