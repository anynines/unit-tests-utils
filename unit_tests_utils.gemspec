# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'unit-tests-utils'
  s.version     = '1.0.0'
  s.date        = '2017-08-02'
  s.summary     = 'Common unit tests utils'
  s.description = 'This gems includes all resources needed for the a9s bosh release unit tests.'
  s.authors     = ['Michael Lieser', 'Dennis Groß']
  s.email       = 'support@anynines.com'
  s.files       = [
    'lib/unit_tests_utils.rb',
    'lib/unit_tests_utils/bosh.rb',
    'lib/unit_tests_utils/consul.rb',
    'lib/unit_tests_utils/internal_dns.rb',
    'lib/unit_tests_utils/manifest.rb'
  ]
  s.homepage    = 'http://www.anynines.com/'
  s.license     = 'Nonstandard'
end
