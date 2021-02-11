require_relative 'cmd'

class UnitTestsUtils::CredHub
  APP = 'credhub'
  GET_COMMAND = 'get'
  GET_BY_NAME_SUB_COMMAND = '--name='
  JSON_FORMAT_SUB_COMMAND = '--output-json'

  COMMAND_FAIL_PREFIX_MESSAGE = 'Command fail: '

  def self.get_by_name(name)
    sub_command = "#{GET_BY_NAME_SUB_COMMAND}'#{name}'"
    execute(GET_COMMAND, sub_command)
  end

  private

  def self.execute(command, sub_command, response_format = JSON_FORMAT_SUB_COMMAND)
    command = "#{APP} #{command} #{sub_command} #{response_format}"
    msg = "#{COMMAND_FAIL_PREFIX_MESSAGE}#{command}"
    UnitTestsUtils::Cmd.exec(command, msg)
  end
end
