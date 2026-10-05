# frozen_string_literal: true

module Ace
  module Hitl
    module Providers
      # ask(question:, ...) result: local event id + relay request id.
      AskResult = Struct.new(:event_id, :request_id, :ref, keyword_init: true)

      # deliver(ref, answer) result; state is :delivered, :retryable
      # (safe to re-push identical content) or :failed.
      DeliverResult = Struct.new(:ref, :state, keyword_init: true)
    end
  end
end
