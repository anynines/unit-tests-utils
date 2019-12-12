require 'open3'

module UnitTestsUtils::Cmd
  # Executes a command on the local machine and throws an error if exit status is not 0 (success)
  def self.exec(command, msg)
    stdout, stderr, exit_status = Open3.capture3(command)
    if !exit_status.nil? && exit_status.to_i > 0
      raise CmdError.new("#{msg} - exit_status: #{exit_status}\nstdout: #{stdout}\nstderr: #{stderr}")
    end
    return stdout, stderr
  end

  class CmdError < StandardError; end
end
