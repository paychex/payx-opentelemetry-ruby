# frozen_string_literal: true

module TraceHeaders
  # Trace Context Headers
  TRACE_CONTEXT = {
    payx_txid_header: 'x-payx-txid',
    payx_reqid_header: 'x-payx-reqid'
  }.freeze

  # Baggage Headers
  BAGGAGE = {
    payx_sid_header: 'x-payx-sid',
    payx_user_header: 'x-payx-user-untrusted',
    payx_bizpn_header: 'x-payx-bizpn',
    payx_cnsmr_header: 'x-payx-cnsmr',
    payx_subtxnbr_header: 'x-payx-subtxnbr'
  }.freeze

  TRACE_FIELDS = [*BAGGAGE.values, *TRACE_CONTEXT.values].freeze
end
