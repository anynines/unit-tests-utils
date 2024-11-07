require_relative 'cmd'

class UnitTestsUtils::CredHub
  APP = 'credhub'.freeze
  GET_COMMAND = 'get'.freeze
  JSON_FORMAT_SUB_COMMAND = '--output-json'.freeze
  COMMAND_FAIL_PREFIX_MESSAGE = 'CredHub command failed:'.freeze

  def self.get_by_name(name)
    stdout, stderr = execute(GET_COMMAND, "--name='#{name}'")
    [JSON.parse(stdout), stderr]
  end

  def self.execute(command, sub_command, response_format = JSON_FORMAT_SUB_COMMAND)
    command = "#{APP} #{command} #{sub_command} #{response_format}"
    UnitTestsUtils::Cmd.exec(command, "#{COMMAND_FAIL_PREFIX_MESSAGE} #{command}")
  end
end
