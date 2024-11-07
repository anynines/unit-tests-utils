require 'spec_helper'

describe UnitTestsUtils::Cmd do
  let(:echo_output) { "echo_output\n" }
  let(:error_message) { 'error_message' }

  describe '.exec' do
    context 'when executing a command with error message' do
      it 'runs the command' do
        stdout, stderr = described_class.exec(
          "echo #{echo_output}",
          msg: 'Failed to execute echo'
        )
        expect(stdout).to eq(echo_output)
        expect(stderr).to be_empty
      end

      it 'failes when command exits is non successful' do
        expect do
          described_class.exec('[ 2 -lt 1 ]', msg: error_message)
        end.to raise_error UnitTestsUtils::Cmd::CmdError
      end
    end
  end

  describe '.exec_with_retry' do
    subject { described_class.exec_with_retry('some error message', retries: 2, backoff: 0) { executed_block } }

    context 'when executing command raised error' do
      let(:some_object) { double(counter: nil) }

      it 'with broken command' do
        def executed_block = UnitTestsUtils::Cmd.exec('[ 2 -lt 1 ]', msg: error_message)

        expect { subject }.to raise_error(UnitTestsUtils::Cmd::CmdError, /#{error_message}/)
      end

      it 'with exceeded counter number' do
        def executed_block = some_object.counter

        expect($stdout).to receive(:puts).with('Attempt number 0 out of 2 retries')
        expect($stdout).to receive(:puts).with('Attempt number 1 out of 2 retries')
        expect($stdout).to receive(:puts).with('Attempt number 2 out of 2 retries')

        expect { subject }.to raise_error(UnitTestsUtils::Cmd::CmdError, /some error message/)
      end
    end

    context 'when command passes' do
      it 'with simple block' do
        def executed_block = 1.+(3)

        expect(subject).to eq 4
      end

      it 'with command inside the block' do
        def executed_block = UnitTestsUtils::Cmd.exec("echo #{echo_output}", msg: 'Failed to execute echo')

        stdout, = subject

        expect(stdout).to eq echo_output
      end
    end
  end
end
