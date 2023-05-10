# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'opentelemetry-payx'
  s.version     = '0.0.1'
  s.summary     = 'Custom Context Propagator to interoparate between Payx t10y standards and OpenTelemetry'
  s.description = 'Custom Context Propagator to interoparate between Payx t10y standards and OpenTelemetry'
  s.authors     = ['Shane Smithrand']
  s.email       = 'ssmithrand@paychex.com'
  s.files       = ['lib/**/*.rb']
  s.license = 'MIT'
  s.required_ruby_version = 3.1

  s.add_dependency 'cgi'
  s.add_dependency 'opentelemetry-api', '~> 1.1.0'
  s.add_dependency 'opentelemetry-common', '~> 0.19.6'
  s.add_dependency 'opentelemetry-sdk', '~> 1.2.0'

  s.add_development_dependency 'bundler', '~> 2.4'
  s.add_development_dependency 'minitest', '~> 5.18.0'
  s.add_development_dependency 'rake', '~> 13.0.6'
  s.add_development_dependency 'rubocop', '~> 1.50.2'
  s.add_development_dependency 'rubocop-minitest'
  s.add_development_dependency 'rubocop-rake'
  s.add_development_dependency 'simplecov', '~> 0.21.2'
  s.add_development_dependency 'yard', '~> 0.9.34'
  s.add_development_dependency 'yard-doctest', '~> 0.1.17'
  s.metadata['rubygems_mfa_required'] = 'true'
end
