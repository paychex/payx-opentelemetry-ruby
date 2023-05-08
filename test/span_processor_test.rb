# frozen_string_literal: true

require 'test_helper'

describe SpanProcessor do
  let(:span_id) do
    '92bb3bf22852475b'
  end

  let(:trace_id) do
    '80f198ee56343ba864fe8b2a57d3eff7'
  end

  let(:trace_flags) do
    OpenTelemetry::Trace::TraceFlags::DEFAULT
  end

  let(:baggage) do
    OpenTelemetry::Baggage
  end

  let(:context) do
    OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace.non_recording_span(
        OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end

  let :mock_span do
    OpenTelemetry::Trace.non_recording_span(
      OpenTelemetry::Trace::SpanContext.new(
        trace_id: Array(trace_id).pack('H*'),
        span_id: Array(span_id).pack('H*'),
        trace_flags: trace_flags
      )
    )
  end

  let(:span_processor) do
    SpanProcessor.new
  end

  let(:tracer_provider) { OpenTelemetry::SDK::Trace::TracerProvider.new }

  let(:tracer) { tracer_provider.tracer('test_component', '1.0') }

  let(:parent_context) do
    OpenTelemetry::Context.empty
  end

  let(:trace_id_header) do
    '80f198ee-5634-3ba8-64fe8b2a57d3eff7'
  end

  let(:req_id_header) do
    '92bb3bf2-2852-475b-9609-04d6d8d51115'
  end

  let(:incoming_cnsmr_header) do
    'payx_service'
  end

  let(:incoming_sid_header) do
    '39d495aa-74a1-4529-8158-7e2b8f4416b0'
  end

  let(:incoming_user_header) do
    'test_user'
  end

  let(:incoming_bizpn_header) do
    'test_business_flow'
  end

  let(:incoming_subtxnbr_header) do
    'a5ee90d7-dded-48c9-b1c9-ffaaaa1a1229'
  end

  let(:cnsmr) do
    'otel_service'
  end

  let(:carrier) do
    {
      'x-payx-txid' => trace_id_header,
      'x-payx-reqid' => req_id_header,
      'x-payx-cnsmr' => incoming_cnsmr_header,
      'x-payx-sid' => incoming_sid_header,
      'x-payx-user-untrusted' => incoming_user_header,
      'x-payx-bizpn' => incoming_bizpn_header,
      'x-payx-subtxnbr' => incoming_subtxnbr_header
    }
  end

  describe '#on_start' do
    it 'iterates through baggage and sets attributes' do
      tracer_provider.add_span_processor(span_processor)
      # Build baggage for test
      payx_context_with_baggage = OpenTelemetry::Baggage.build(context: parent_context) do |builder|
        carrier.each do |key, value|
          builder.set_value(key, value)
        end
      end

      OpenTelemetry::Context.with_current(payx_context_with_baggage) do
        span = tracer.start_span('hello', with_parent: OpenTelemetry::Context.current)
        span.attributes.each do |key, _value|
          refute_includes(key, '-', 'attribute contains dashes') if key.include?('payx')
        end
      end
    end
  end
end
