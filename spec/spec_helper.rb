require 'rspec'
require 'json'
require_relative '../lib/unit_tests_utils'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
