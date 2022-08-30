# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'opentelemetry-propagator-payx'
  s.version     = '0.0.1'
  s.summary     = 'Custom Context Propagator to interoparate between Payx t10y standards and OpenTelemetry'
  s.description = 'Custom Context Propagator to interoparate between Payx t10y standards and OpenTelemetry'
  s.authors     = ['Shane Smithrand']
  s.email       = 'ssmithrand@paychex.com'
  s.files       = ['lib/**/*.rb']
  s.license = 'MIT'

  s.add_dependency 'cgi'
  s.add_dependency 'opentelemetry-api', '~> 1.0'
  s.add_dependency 'opentelemetry-common'

  s.add_development_dependency 'bundler', '>= 1.17'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rubocop', '~> 1.3.0'
  s.add_development_dependency 'rubocop-minitest'
  s.add_development_dependency 'rubocop-rake'
  s.add_development_dependency 'simplecov', '~> 0.17.1'
  s.add_development_dependency 'yard', '~> 0.9'
  s.add_development_dependency 'yard-doctest', '~> 0.1.6'
  s.metadata['rubygems_mfa_required'] = 'true'
end
