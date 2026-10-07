# frozen_string_literal: true

require_relative "protected_service_receiver"

module Ace
  module Lab
    module Organisms
      # One admitted worker for one installed receiver. Capacity is acquired
      # before the canonical claim, not after an accepted request. This owns
      # execution lifetime only; it never substitutes for canonical status.
      class ProtectedServiceWorker
        def initialize(receiver:)
          @receiver = receiver
          @mutex = Mutex.new
          @worker = nil
          @closing = false
        end

        def start(submission:, peer:, input_bytes:, mutation_id:, on_claim:, deadline: nil)
          raise ArgumentError, "receiver acceptance callback unavailable" unless on_claim.respond_to?(:call)
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          deadline ||= now + 5
          unless deadline.is_a?(Numeric) && deadline.finite? && deadline > now && deadline <= now + 5
            raise ArgumentError, "receiver acceptance deadline is invalid"
          end
          # Hold independent copies before returning to the socket handler.
          submission = copy(submission)
          peer = copy(peer)
          input_bytes = input_bytes.dup.freeze
          mutation_id = mutation_id.dup.freeze
          @mutex.synchronize do
            raise Ace::Assign::AttemptErrors::Conflict, "receiver capacity unavailable" if @closing || @worker&.alive?

            @worker = Thread.new do
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              next({"state" => "uncertain"}) unless remaining.positive?
              @receiver.execute(submission: submission, peer: peer, input_bytes: input_bytes,
                mutation_id: mutation_id, claim_timeout: [remaining, 5].min,
                on_claim: lambda do |identity|
                  begin
                    on_claim.call(identity)
                  rescue IOError, SystemCallError
                    # A lost acceptance reply cannot cancel already admitted
                    # work or cause a second execution. Status owns recovery.
                    nil
                  end
                end)
            end
          end
        end

        # Stop admission before joining. A timed-out join preserves both the
        # worker and closing state; the listener must retain its lifetime lock.
        def close(timeout:)
          unless timeout.is_a?(Numeric) && timeout.finite? && timeout >= 0
            raise ArgumentError, "receiver close deadline is invalid"
          end
          worker = @mutex.synchronize do
            @closing = true
            @worker
          end
          !worker || !worker.join(timeout).nil?
        end

        private

        def copy(value)
          duplicate = JSON.parse(JSON.generate(value))
          freeze_value(duplicate)
        end

        def freeze_value(value)
          value.each_value { |child| freeze_value(child) } if value.is_a?(Hash)
          value.each { |child| freeze_value(child) } if value.is_a?(Array)
          value.freeze
        end
      end
    end
  end
end
