require 'spec_helper'

describe UnitTestsUtils::CredHub do
  describe '#get_by_name' do
    let(:name) { 'anything' }
    subject(:get_by_name) { UnitTestsUtils::CredHub.get_by_name(name) }

    it 'executes with the right command' do
      command_expected = "credhub get --name='#{name}' --output-json"
      msg_expected = "#{UnitTestsUtils::CredHub::COMMAND_FAIL_PREFIX_MESSAGE} #{command_expected}"
      allow(UnitTestsUtils::Cmd).to receive(:exec)
        .with(command_expected, msg_expected)
        .and_return('{}')

      get_by_name
    end
  end
end
