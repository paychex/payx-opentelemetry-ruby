# frozen_string_literal: true

require_relative './trace_headers'
require 'opentelemetry/sdk'

# Author Shane Smithrand <ssmithrand@paychex.com>
# Custom Span Processor Implementation that copies baggage tied to the span into span attributes.
# This way, Collector can process and export baggage to log file.
# SpanProcessor describes a duck type and provides synchronous no-op hooks for when a
# {Span} is started or when a {Span} is ended. It is not required to subclass this
# class to provide an implementation of SpanProcessor, provided the interface is
# satisfied.
class SpanProcessor < OpenTelemetry::SDK::Trace::SpanProcessor
  include ::TraceHeaders

  # Called when a {Span} is started, if the {Span#recording?}
  # returns true.
  #
  # This method is called synchronously on the execution thread, should
  # not throw or block the execution thread.
  #
  # This specific implementation of the on_start interface loops through baggage
  # and sets span attributes so the collector can see them and log them out appropiately.
  #
  # @param [Span] span the {Span} that just started.
  # @param [Context] parent_context the parent {Context} of the newly
  #  started span.
  def on_start(span, parent_context)
    span.set_attribute('instrumentation.library', span.instrumentation_scope.name)
    OpenTelemetry::Baggage.values(context: parent_context).each do |key, value|
      found_baggage = TRACE_FIELDS.include? key
      next unless found_baggage

      key = key.gsub('-', '.')
      span.set_attribute(key, value)
    end
  end

  # Called when a {Span} is ended, if the {Span#recording?}
  # returns true.
  #
  # Nothing to do at finish.
  #
  # @param [Span] span the {Span} that just ended.
  def on_finish(_span); end
end
