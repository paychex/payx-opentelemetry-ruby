# frozen_string_literal: true

require 'test_helper'

describe Propagator do
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

  let(:propagator) do
    Propagator.new
  end

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

  describe '#extract' do
    describe 'given a valid txid and reqid' do
      it 'successfully extracts trace context headers and baggage' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context
        extracted_baggage = OpenTelemetry::Baggage.values(context: context)

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).must_equal(span_id)

        carrier.each do |key, value|
          _(extracted_baggage[key]).must_equal(value)
        end
      end
    end

    describe 'given an invalid txid' do
      it 'returns context unmodified' do
        carrier['x-payx-txid'] = nil
        context = propagator.extract(carrier, context: parent_context)
        _(parent_context).must_equal(context)
      end
    end

    describe 'given an invalid reqid' do
      it 'generates a new span id and continues' do
        carrier['x-payx-reqid'] = 'unk,1234'
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context
        extracted_baggage = OpenTelemetry::Baggage.values(context: context)

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).wont_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)

        carrier.each do |key, value|
          _(extracted_baggage[key]).must_equal(value)
        end
      end
    end

    describe 'given a reqid already in spanid format' do
      it 'sets spanid accordingly and continues' do
        carrier['x-payx-reqid'] = span_id
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context
        extracted_baggage = OpenTelemetry::Baggage.values(context: context)

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).wont_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
        _(extracted_context.hex_span_id).must_equal(span_id)
        carrier.each do |key, value|
          _(extracted_baggage[key]).must_equal(value)
        end
      end
    end
  end

  describe '#inject' do
    describe 'context originated from a Payx t10y service' do
      it 'injects original values as headers' do
        payx_context_with_baggage = OpenTelemetry::Baggage.build(context: context) do |builder|
          carrier.each do |key, value|
            builder.set_value(key, value)
          end
        end
        carrier = {}
        propagator.inject(carrier, context: payx_context_with_baggage)
        OpenTelemetry::Baggage.values(context: payx_context_with_baggage).each do |key, value|
          if key == 'x-payx-cnsmr'
            _(carrier.fetch(key)).must_equal(cnsmr)
          else
            _(carrier.fetch(key)).must_equal(value)
          end
        end
      end
    end

    describe 'context originated from otel service' do
      it 'injects otel values as headers' do
        propagator.inject(carrier, context: context)
        _(carrier.fetch('x-payx-txid')).must_equal(trace_id)
        _(carrier.fetch('x-payx-reqid')).must_equal(span_id)
        _(carrier.fetch('x-payx-cnsmr')).must_equal(cnsmr)
      end
    end
  end
end
