# frozen_string_literal: true

# SPDX-License-Identifier: Apache-2.0

require 'cgi'
require 'opentelemetry-common'
require 'opentelemetry-api'
require_relative './Constants/trace_headers'
# Author Shane Smithrand <ssmithrand@paychex.com>
# Based on the Jaeger Propagator and Mike Richards' <mrichars3@paychex.com> .NET Payx Propagator
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.

class OpenTelemetryPropagatorPayx
  include ::OpenTelemetry
  include ::TraceHeaders
  CNSMR = ENV.fetch('OTEL_SERVICE_NAME', nil)
  # Extract trace context from the supplied carrier.
  # If extraction fails, the original context will be returned
  #
  # @param [Carrier] carrier The carrier to get the header from
  # @param [optional Context] context Context to be updated with the trace context
  #   extracted from the carrier. Defaults to +Context.current+.
  # @param [optional Getter] getter If the optional getter is provided, it
  #   will be used to read the header from the carrier, otherwise the default
  #   text map getter will be used.
  #
  # @return [Context] context updated with extracted baggage, or the original context
  #   if extraction fails
  def extract(carrier, context: Context.current, getter: Common::Propagation.rack_env_getter)
    trace_id = getter.get(carrier, TRACE_CONTEXT[:payx_txid_header])
    span_id  = getter.get(carrier, TRACE_CONTEXT[:payx_reqid_header])

    return context unless trace_id

    trace_id = to_trace_id(trace_id.gsub('-', ''))
    span_id  = to_span_id(span_id.gsub('-', '').slice(0, 16))

    span_context = Trace::SpanContext.new(
      trace_id: trace_id,
      span_id: span_id,
      trace_flags: Trace::TraceFlags::SAMPLED,
      remote: true
    )
    span = OpenTelemetry::Trace.non_recording_span(span_context)
    context = context_with_extracted_baggage(carrier, context, getter)
    OpenTelemetry::Trace.context_with_span(span, parent_context: context)
  end

  # Inject trace context into the supplied carrier.
  #
  # @param [Carrier] carrier The mutable carrier to inject trace context into
  # @param [Context] context The context to read trace context from
  # @param [optional Setter] setter If the optional setter is provided, it
  #   will be used to write context into the carrier, otherwise the default
  #   text map setter will be used.
  def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
    span_context = OpenTelemetry::Trace.current_span(context).context
    return unless span_context.valid?

    # Could be overwritten if found in baggage
    # which means this is not a call originating from an otel-instrumented service
    setter.set(carrier, TRACE_CONTEXT[:payx_txid_header], span_context.hex_trace_id)

    # Could be overwritten if found in baggage
    # which means this is not a call originating from an otel-instrumented service
    setter.set(carrier, TRACE_CONTEXT[:payx_reqid_header], span_context.hex_span_id)

    OpenTelemetry::Baggage.values(context: context).each do |key, value|
      found_baggage = TRACE_FIELDS.include? key
      next unless found_baggage

      setter.set(carrier, key, value)
    end

    # Set after baggage to ensure baggage cnsmr key gets overridden
    # with *this service's* consumer value.
    setter.set(carrier, BAGGAGE[:payx_cnsmr_header], CNSMR)
  end

  # Returns the predefined propagation fields. If your carrier is reused, you
  # should delete the fields returned by this method before calling +inject+.
  #
  # @return [Array<String>] a list of fields that will be used by this propagator.
  def fields
    TRACE_FIELDS
  end

  private

  def context_with_extracted_baggage(carrier, context, getter)
    OpenTelemetry::Baggage.build(context: context) do |b|
      getter.keys(carrier).each do |carrier_key|
        found_baggage = TRACE_FIELDS.include? carrier_key
        next unless found_baggage

        raw_value = getter.get(carrier, carrier_key)
        value = CGI.unescape(raw_value)
        b.set_value(carrier_key, value)
      end
    end
  end

  def to_span_id(span_id_str)
    [span_id_str.rjust(16, '0')].pack('H*')
  end

  def to_trace_id(trace_id_str)
    [trace_id_str.rjust(32, '0')].pack('H*')
  end
end
