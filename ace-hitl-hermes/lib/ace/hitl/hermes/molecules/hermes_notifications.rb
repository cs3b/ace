# frozen_string_literal: true

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Deterministic single-line notification texts (spec 8wm.t.vs1 §9):
        # no clock, no colors, only provided values. The address is the
        # message address `<machine>/<folder>/<id>`. Emission is an
        # injectable sink (default silent in Box).
        module HermesNotifications
          EVENTS = %w[
            question_received
            answer_written
            delivered
            acked
            quarantined
            retry_scheduled
            retry_exhausted
          ].freeze

          module_function

          # Builds the notification line for an event. Unknown events fail
          # closed so a typo cannot silently drop notifications.
          def emit(event, address:, **details)
            line =
              case event.to_s
              when "question_received"
                "hermes: question #{address} received"
              when "answer_written"
                "hermes: answer #{address} written"
              when "delivered"
                "hermes: #{address} delivered"
              when "acked"
                "hermes: #{address} acked (file deleted)"
              when "quarantined"
                "hermes: #{address} quarantined (#{details[:reason]})"
              when "retry_scheduled"
                "hermes: #{address} retry #{details[:attempt]}/#{details[:max_attempts]} " \
                  "(#{details[:policy]})"
              when "retry_exhausted"
                "hermes: #{address} retries exhausted (#{details[:reason]})"
              else
                raise ContractError,
                  "unknown hermes notification event #{event.inspect} " \
                  "(known: #{EVENTS.join(', ')})"
              end
            line
          end
        end
      end
    end
  end
end
