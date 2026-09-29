# frozen_string_literal: true

require "securerandom"

require "ace/llm/models/execution_evidence"

module Ace
  module LLM
    module Providers
      module CLI
        module Models
          # Typed outcome of one SafeCapture subprocess invocation.
          #
          # Carries the raw captured streams and the process facts (outcome kind,
          # exit/signal, configured deadline, monotonic elapsed time, invocation
          # correlation ID) so classification downstream can key on evidence
          # instead of error-message prose. Raw streams stay internal to this
          # object; only bounded excerpts leave through #execution_evidence.
          #
          # This is a model - pure immutable data.
          class CaptureResult
            OUTCOME_COMPLETED = :completed
            OUTCOME_DEADLINE_EXCEEDED = :deadline_exceeded
            OUTCOME_TRANSPORT_FAILURE = :transport_failure
            OUTCOME_SPAWN_FAILURE = :spawn_failure

            # Generate the correlation ID for an invocation before spawning.
            # @return [String] opaque 8-character ID
            def self.next_invocation_id
              SecureRandom.alphanumeric(8)
            end

            # @param outcome [Symbol] one of the OUTCOME_* constants
            # @param stdout [String] captured stdout (empty when nothing captured)
            # @param stderr [String] captured stderr (empty when nothing captured)
            # @param status [Process::Status, nil] exit status (nil when the process never exited on its own)
            # @param signal [String, nil] terminating signal name (derived from status when not given)
            # @param provider_name [String] human-facing provider label
            # @param invocation_id [String] correlation ID generated before spawn
            # @param deadline_seconds [Numeric, nil] configured deadline
            # @param elapsed_seconds [Numeric, nil] monotonic elapsed time
            # @param spawn_error [Exception, nil] exception that prevented spawning
            def initialize(outcome:, stdout: "", stderr: "", status: nil, signal: nil, provider_name: "CLI",
              invocation_id: Models::CaptureResult.next_invocation_id, deadline_seconds: nil,
              elapsed_seconds: nil, spawn_error: nil)
              @outcome = outcome
              @stdout = stdout.to_s
              @stderr = stderr.to_s
              @status = status
              @signal = signal
              @provider_name = provider_name
              @invocation_id = invocation_id
              @deadline_seconds = deadline_seconds
              @elapsed_seconds = elapsed_seconds
              @spawn_error = spawn_error
              freeze
            end

            attr_reader :outcome, :stdout, :stderr, :status, :signal, :provider_name,
              :invocation_id, :deadline_seconds, :elapsed_seconds, :spawn_error

            # True when the process ran to its own completion and exited zero.
            def success?
              outcome == OUTCOME_COMPLETED && status&.success? ? true : false
            end

            # True when the provider process was actually spawned. Failed spawns
            # never began execution, so replaying them cannot repeat side effects.
            def execution_began?
              outcome != OUTCOME_SPAWN_FAILURE
            end

            def exit_status
              status&.exitstatus
            end

            def signal
              return @signal if @signal
              return nil if outcome == OUTCOME_SPAWN_FAILURE

              termsig = status&.termsig
              termsig ? (Signal.list.key(termsig) || "signal #{termsig}") : nil
            end

            # Structured evidence for classification, with bounded output excerpts.
            # @return [Ace::LLM::Models::ExecutionEvidence]
            def execution_evidence
              Ace::LLM::Models::ExecutionEvidence.new(
                outcome: evidence_outcome,
                invocation_id: invocation_id,
                provider_name: provider_name,
                deadline_seconds: deadline_seconds,
                elapsed_seconds: elapsed_seconds,
                exit_status: exit_status,
                signal: signal,
                execution_began: execution_began?,
                stdout_excerpt: stdout,
                stderr_excerpt: stderr
              )
            end

            # Build the ProviderError describing this outcome, with evidence attached.
            # @return [Ace::LLM::ProviderError]
            def provider_error(message = nil)
              error = Ace::LLM::ProviderError.new(message || default_error_message)
              error.execution_evidence = execution_evidence
              error
            end

            # Raise ProviderError unless the invocation completed with exit 0.
            # Deadline expiry, transport failure, spawn failure, and nonzero exit
            # each surface as a distinct, evidence-carrying error.
            def raise_unless_success
              raise provider_error unless success?

              self
            end

            # Attach "session ended without a final response" evidence to an error
            # raised while parsing a completed (exit-zero) capture — e.g. a CLI
            # that exited cleanly but produced no final message.
            # @param error [Ace::LLM::ProviderError]
            # @return [Ace::LLM::ProviderError]
            def with_no_response_evidence(error)
              evidence = Ace::LLM::Models::ExecutionEvidence.new(
                outcome: :no_response,
                invocation_id: invocation_id,
                provider_name: provider_name,
                deadline_seconds: deadline_seconds,
                elapsed_seconds: elapsed_seconds,
                exit_status: exit_status,
                execution_began: true,
                stdout_excerpt: stdout,
                stderr_excerpt: stderr
              )
              error.execution_evidence ||= evidence
              error
            end

            private

            def evidence_outcome
              case outcome
              when OUTCOME_COMPLETED then :nonzero_exit
              when OUTCOME_DEADLINE_EXCEEDED then :deadline_exceeded
              when OUTCOME_TRANSPORT_FAILURE, OUTCOME_SPAWN_FAILURE then :transport_failure
              end
            end

            def default_error_message
              case outcome
              when OUTCOME_DEADLINE_EXCEEDED
                "#{provider_name} CLI execution exceeded its #{format_seconds(deadline_seconds)} deadline"
              when OUTCOME_TRANSPORT_FAILURE
                "#{provider_name} CLI session ended unexpectedly" + (signal ? " (#{signal})" : "")
              when OUTCOME_SPAWN_FAILURE
                "#{provider_name} CLI could not be started: #{spawn_error_class}"
              else
                base = "#{provider_name} CLI failed with exit status #{exit_status}"
                (detail = failure_detail) ? "#{base}: #{detail}" : base
              end
            end

            # First non-empty captured line, bounded and redacted — keeps
            # actionable CLI diagnostics in the error without leaking
            # transcripts or credentials.
            def failure_detail
              source = [stderr, stdout].map { |stream| stream.to_s.lines.map(&:strip) }.flatten
              detail = source.reject(&:empty?).first.to_s
              detail = Ace::LLM::Models::ExecutionEvidence.redact(detail)
              detail = "#{detail[0, 300]}…[truncated]" if detail.length > 300
              detail.empty? ? nil : detail
            end

            def spawn_error_class
              spawn_error ? spawn_error.class.name : "unknown error"
            end

            def format_seconds(value)
              value.is_a?(Numeric) ? format("%.1fs", value) : value.to_s
            end
          end
        end
      end
    end
  end
end
