Gem::Specification.new do |s|
  s.name        = 'unit-tests-utils'
  s.version     = '2.13.0'
  s.date        = '2021-03-11'
  s.summary     = 'unit-tests-utils'
  s.description = 'Unit tests used to test a9s Data Services'
  s.authors     = %w[Test1 Test2]
  s.email       = 'ds-team@anynines.com'
  s.homepage    = 'https://github.com/anynines/unit-tests-utils'
  s.license     = 'Nonstandard'
  s.files       = [
      'lib/unit_tests_utils/postgresql_web_service_client.rb',
      'lib/unit_tests_utils/template_render.rb',
      'lib/unit_tests_utils/internal_dns.rb',
      'lib/unit_tests_utils/consul.rb',
      'lib/unit_tests_utils/bosh.rb',
      'lib/unit_tests_utils/postgresql_client.rb',
      'lib/unit_tests_utils/rspec_logger.rb',
      'lib/unit_tests_utils/credhub.rb',
      'lib/unit_tests_utils/traversal.rb',
      'lib/unit_tests_utils/cmd.rb',
      'lib/unit_tests_utils/manifest.rb',
      'lib/unit_tests_utils/git.rb',
      'lib/unit_tests_utils/turbulence.rb',
      'lib/unit_tests_utils.rb'
  ]
end
