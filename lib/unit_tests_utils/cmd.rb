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

  def self.exec_with_retry(error_message, backoff: 5, retries: 1200)
    counter = 0

    while ! result = yield do
      sleep(backoff)

      puts "Attempt number #{counter} out of #{retries} retries"

      if counter >= retries
        raise CmdError.new(error_message)
      end

      counter += 1
    end

    return result
  end   

  class CmdError < StandardError; end
end
