require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::RspecLogger do
  context 'when buffering' do
    subject(:logger) do
      UnitTestsUtils::RspecLogger.instance.tap do |i|
        i.io_output = StringIO.new
      end
    end

    before do
      logger.clear

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

    describe '#print' do
      it "outputs all messages" do
        logger.print

        logger.io_output.rewind
        o = logger.io_output.read

        ['message0', 'message1'].each do |m|
          expect(o).to match(/#{m}/)
        end
      end
    end
  end
end
