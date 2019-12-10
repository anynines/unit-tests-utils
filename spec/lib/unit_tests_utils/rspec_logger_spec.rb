require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::RspecLogger do
  context 'when buffering' do
    subject(:logger) { UnitTestsUtils::RspecLogger.instance }

    before do
      logger.debug('message0')
      logger.debug('message1')
    end

    describe 'buffer' do
      it 'buffers messages' do
        expect(logger.buffer.length).to eql(2)
      end
    end

    describe '#clear' do
      it 'clears the buffer' do
        logger.clear

        expect(logger.buffer.length).to eql(0)
      end
    end
  end
end
