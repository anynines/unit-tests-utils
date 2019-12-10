class UnitTestsUtils::RspecLogger

  def initialize
    @buffer = []
    @live_log = !ENV['UNIT_TEST_DEBUG'].nil? && ENV['UNIT_TEST_DEBUG'] == "true"
  end

  @@instance = UnitTestsUtils::RspecLogger.new

  def self.instance
    @@instance
  end

  attr_reader :buffer

  def debug(message)
    method = caller_locations.first
    append("[#{method.base_label}:#{method.lineno}] - #{message}")
  end

  def print
    buffer.each do |message|
      puts message
    end
  end

  def clear
    buffer.clear
  end

  private_class_method :new


  attr_reader :live_log

  def append(message)
    if live_log
      puts "#{(object_id << 1)} - #{message}"
    else
      buffer.push(message)
    end
  end
end
