# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'unit-tests-utils'
  s.version     = '1.2.0'
  s.date        = '2017-11-22'
  s.summary     = 'Common unit tests utils'
  s.description = 'This gems includes all resources needed for the a9s BOSH release unit tests.'
  s.authors     = ['Michael Lieser', 'Dennis Groß', 'Lucas Pinto']
  s.email       = 'support@anynines.com'
  s.files       = [
    'lib/unit_tests_utils.rb',
    'lib/unit_tests_utils/bosh.rb',
    'lib/unit_tests_utils/consul.rb',
    'lib/unit_tests_utils/internal_dns.rb',
    'lib/unit_tests_utils/manifest.rb',
    'lib/unit_tests_utils/git.rb'
  ]
  s.homepage    = 'http://www.anynines.com/'
  s.license     = 'Nonstandard'
end
