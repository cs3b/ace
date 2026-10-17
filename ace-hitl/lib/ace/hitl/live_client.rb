# frozen_string_literal: true

require "ace/hitl/contract"
require_relative "providers/lab"

module Ace
  module Hitl
    # Client of the authenticated lifecycle boundary. The installed
    # attempt-bound native delivery path (Herdr inbox reconciliation and its
    # ace-assign attempt authority) was removed with the old authority model;
    # requester-side boundary operations remain.
    class LiveClient
      def initialize(boundary: nil)
        @boundary = boundary
      end

      # Pane-less waiting consumes the existing authorized request through
      # the authenticated boundary. It neither queues an answer nor attests
      # native/effect completion. OTP bytes remain solely in this
      # authenticated return value.
      def wait(request:, timeout: 0, operation: nil)
        boundary.consume(request, timeout: timeout, operation: operation)
      end

      def status(request:)
        facts = boundary.read(request)
        envelope = envelope_for(facts, request)
        {"request_id" => request, "request_state" => facts["state"], "envelope" => envelope}
      end

      def pending(project: nil)
        boundary.pending(project: project)
      end

      private

      def envelope_for(result, request)
        Contract::ManagedEnvelope.load(result.fetch("envelope"), expected: {
          request_id: request, correlation_id: request, assignment_id: result["assignment"], attempt_id: result["attempt"]
        })
      rescue Contract::InvalidEnvelope, KeyError => e
        raise Lifecycle::BindingError, "managed request binding is invalid (#{e.message})"
      end

      def boundary
        @boundary ||= Providers::Lab.boundary_client
      end
    end
  end
end
