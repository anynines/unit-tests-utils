require 'rspec'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |f| puts f; require f }

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end


