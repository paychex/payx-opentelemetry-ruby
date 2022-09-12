# frozen_string_literal: true

ENV['OTEL_SERVICE_NAME'] = 'otel_service'
ENV['ENABLE_COVERAGE'] = '1'
if ENV['ENABLE_COVERAGE'].to_i.positive?
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'opentelemetry-api'
require 'opentelemetry_propagator_payx'

OpenTelemetry.logger = Logger.new(File::NULL)
