# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'unit-tests-utils'
  s.version     = '2.14.0'
  s.date        = '2022-08-26'
  s.summary     = 'Common unit tests utils'
  s.description = 'This gems includes all resources needed for the a9s BOSH release unit tests.'
  s.authors     = ['Michael Lieser', 'Dennis Groß', 'Lucas Pinto', 'Kevin Konrad',
                    'Jens Breuer', 'Khaled Blah', 'Morgan Hill', 'Thomas Bruckmann',
                    'Robert Gogolok', 'Heitor Meira', 'Cedrik Heusser', 'Francisco Germano']
  s.email       = 'support@anynines.com'
  s.files       = [
    'lib/unit_tests_utils.rb',
    'lib/unit_tests_utils/bosh.rb',
    'lib/unit_tests_utils/credhub.rb',
    'lib/unit_tests_utils/consul.rb',
    'lib/unit_tests_utils/git.rb',
    'lib/unit_tests_utils/internal_dns.rb',
    'lib/unit_tests_utils/manifest.rb',
    'lib/unit_tests_utils/postgresql_web_service_client.rb',
    'lib/unit_tests_utils/turbulence.rb',
  ]
  s.homepage    = 'http://www.anynines.com/'
  s.license     = 'Nonstandard'

  s.add_runtime_dependency 'httparty', '0.21.0'
  s.add_runtime_dependency 'pg', '0.19'
end
