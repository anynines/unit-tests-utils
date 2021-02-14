require_relative 'cmd'

class UnitTestsUtils::CredHub
  APP = 'credhub'
  GET_COMMAND = 'get'
  JSON_FORMAT_SUB_COMMAND = '--output-json'
  COMMAND_FAIL_PREFIX_MESSAGE = 'CredHub command failed:'

  def self.get_by_name(name)
    execute(GET_COMMAND, "--name='#{name}'")
  end

  private

  def self.execute(command, sub_command, response_format = JSON_FORMAT_SUB_COMMAND)
    command = "#{APP} #{command} #{sub_command} #{response_format}"
    UnitTestsUtils::Cmd.exec(command, "#{COMMAND_FAIL_PREFIX_MESSAGE} #{command}")
  end
end
