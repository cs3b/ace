# frozen_string_literal: true

require "digest"
require "ace/assign"
require "ace/herdr"
require_relative "providers/lab"

module Ace
  module Hitl
    # Explicit in-process client. The scoped service owns answer availability
    # and business callbacks; Herdr owns delivery to the selected live terminal.
    # A watcher lives only as long as its requesting agent. Delivery status is
    # read from that original Inbox owner, never a duplicate recovery projection.
    class LiveClient
      def initialize(boundary: nil, coordinator: nil, inbox: nil, root: Dir.pwd)
        @boundary = boundary
        @coordinator = coordinator
        @inbox = inbox
        @root = root
      end

      # Pane-less waiting consumes the existing authorized request through
      # protected IPC. It neither queues an answer nor attests native/effect
      # completion. OTP bytes remain solely in this authenticated return value.
      def wait(request:, timeout: 0, operation: nil)
        boundary.consume(request, timeout: timeout, operation: operation)
      end

      def watch(request:, timeout: 0, &observer)
        Thread.new do
          result = deliver(request: request, timeout: timeout)
          observer.call(result) if observer
          result
        end
      end

      def deliver(request:, timeout: 0)
        facts = boundary.read(request)
        envelope = envelope_for(facts, request)
        raise Lifecycle::StateError, "OTP answers require protected consume; native/folder delivery is prohibited" if envelope["kind"] == "otp"
        reverse = envelope["reverse"]
        raise Lifecycle::BindingError, "request has no verified native reverse address" unless reverse
        owner = coordinator.runtime_binding(attempt_id: envelope["attempt_id"], caller_pid: Process.pid)
        unless owner.values_at("session", "pane") == reverse.values_at("session", "pane")
          raise Lifecycle::BindingError, "request reverse differs from its exact active native owner"
        end
        target = inbox.target_from_owner(owner)
        result = boundary.consume(request, timeout: timeout, native_delivery: true)
        raise Lifecycle::StateError, "native delivery claim was not committed" unless result["native_delivery"] == true
        consumed = envelope_for(result, request)
        unless consumed == envelope
          raise Lifecycle::BindingError, "request binding changed during answer consumption"
        end
        answer = result["answer"]
        unless answer.is_a?(String) && !answer.empty?
          raise Lifecycle::StateError, "ordinary answer is unavailable for native delivery"
        end
        delivery = envelope.merge("payload_sha256" => Digest::SHA256.hexdigest(answer))
        if result["effect_receipt_ref"] && delivery["effect"]
          delivery["effect"] = delivery["effect"].merge("receipt_ref" => result["effect_receipt_ref"])
        end
        delivery = Contract::ManagedEnvelope.load(delivery)
        raise Lifecycle::AnswerError, "secret-bearing native answers are prohibited" if Contract::SecretGate::PATTERN.match?(answer)
        event = event_id(envelope)
        queued = inbox.enqueue(event: event, attempt: envelope["attempt_id"], ref: reverse, payload: answer,
          managed_envelope: delivery, expected_target: target)
        coordinator.bind_inbox(attempt_id: envelope["attempt_id"], event_id: event, inbox: inbox)
        inbox.deliver(event: event)
      ensure
        answer&.clear unless answer&.frozen?
      end

      def status(request:)
        facts = boundary.read(request)
        envelope = envelope_for(facts, request)
        {"request_id" => request, "request_state" => facts["state"], "envelope" => envelope,
         "delivery" => envelope["kind"] == "otp" ? {"state" => "not-applicable"} : delivery_status(envelope)}
      end

      def pending(project: nil)
        boundary.pending(project: project).filter_map do |facts|
          next facts unless facts["native_delivery"] == true
          envelope = envelope_for(facts, facts["id"])
          delivery = delivery_status(envelope)
          next if delivery["state"] == "delivered"
          facts.merge("delivery" => delivery)
        end
      end

      private

      def delivery_status(envelope)
        event = event_id(envelope)
        # This is transport history from its original owner, not proof that
        # an agent read an answer or a cached view of the current terminal.
        inbox.status(event: event)
      rescue Ace::Herdr::Organisms::Inbox::MissingEventError
        {"event_id" => event, "state" => "not-submitted"}
      end

      def envelope_for(result, request)
        Contract::ManagedEnvelope.load(result.fetch("envelope"), expected: {
          request_id: request, correlation_id: request, assignment_id: result["assignment"], attempt_id: result["attempt"]
        })
      rescue Contract::InvalidEnvelope, KeyError => e
        raise Lifecycle::BindingError, "managed request binding is invalid (#{e.message})"
      end

      def event_id(envelope)
        Contract::ManagedEnvelope.inbox_event_id(envelope)
      end

      def boundary
        @boundary ||= Providers::Lab.boundary_client
      end

      def coordinator
        @coordinator ||= Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @root)
      end

      def inbox
        @inbox ||= Ace::Herdr::Organisms::Inbox.from_config(root: @root)
      end
    end
  end
end
