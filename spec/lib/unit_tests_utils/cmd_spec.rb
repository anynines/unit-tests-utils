require 'spec_helper'

describe UnitTestsUtils::Cmd do
  describe ".exec" do
    let(:echo_output) { "echo_output\n" }
    let(:error_message) { "error_message" }

    context "when executing a command with error message" do
      it "runs the command" do
        stdout, stderr = UnitTestsUtils::Cmd.exec("echo #{echo_output}",
                                                  msg: "Failed to execute echo")
        expect(stdout).to eq(echo_output)
        expect(stderr).to be_empty
      end

      it "failes when command exits is non successful" do
        expect do
          UnitTestsUtils::Cmd.exec("[ 2 -lt 1 ]", msg: error_message)
        end.to raise_error UnitTestsUtils::Cmd::CmdError
      end
    end
  end
end
