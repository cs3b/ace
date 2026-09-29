# frozen_string_literal: true

module Ace
  module LLM
    module Models
      # Structured evidence about how a CLI provider execution actually ended.
      #
      # Built at the subprocess boundary (ace-llm-providers-cli SafeCapture) and
      # attached to Ace::LLM::ProviderError instances so classification and
      # fallback decisions can key on observed process facts instead of error
      # message prose. Carries bounded output excerpts only — never the full
      # streams, prompt content, or environment.
      #
      # This is a model - pure immutable data.
      class ExecutionEvidence
        OUTCOMES = %i[
          deadline_exceeded
          transport_failure
          nonzero_exit
          no_response
        ].freeze

        EXCERPT_LIMIT = 2000

        attr_reader :outcome, :invocation_id, :provider_name, :deadline_seconds,
          :elapsed_seconds, :exit_status, :signal, :execution_began,
          :stdout_excerpt, :stderr_excerpt

        # @param outcome [Symbol] one of OUTCOMES
        # @param invocation_id [String, nil] opaque correlation ID generated before spawn
        # @param provider_name [String, nil] human-facing provider label (e.g. "Codex")
        # @param deadline_seconds [Numeric, nil] configured deadline for the invocation
        # @param elapsed_seconds [Numeric, nil] monotonic elapsed time of the invocation
        # @param exit_status [Integer, nil] process exit code when the process exited
        # @param signal [String, nil] signal name when the process was terminated by one
        # @param execution_began [Boolean] true when the provider process was actually spawned
        # @param stdout_excerpt [String, nil] bounded excerpt of captured stdout
        # @param stderr_excerpt [String, nil] bounded excerpt of captured stderr
        def initialize(outcome:, invocation_id: nil, provider_name: nil, deadline_seconds: nil,
          elapsed_seconds: nil, exit_status: nil, signal: nil, execution_began: true,
          stdout_excerpt: nil, stderr_excerpt: nil)
          raise ArgumentError, "unknown outcome #{outcome.inspect}" unless OUTCOMES.include?(outcome)

          @outcome = outcome
          @invocation_id = invocation_id
          @provider_name = provider_name
          @deadline_seconds = deadline_seconds
          @elapsed_seconds = elapsed_seconds
          @exit_status = exit_status
          @signal = signal
          @execution_began = execution_began
          @stdout_excerpt = bounded_excerpt(stdout_excerpt)
          @stderr_excerpt = bounded_excerpt(stderr_excerpt)
          freeze
        end

        # Build evidence from a plain hash (e.g. deserialized metadata)
        # @param hash [Hash]
        # @return [ExecutionEvidence]
        def self.from_h(hash)
          return nil unless hash.is_a?(Hash)

          symbolized = hash.each_with_object({}) { |(key, value), acc| acc[key.to_sym] = value }
          outcome = symbolized[:outcome].to_s.to_sym
          return nil unless OUTCOMES.include?(outcome)

          new(
            outcome: outcome,
            invocation_id: symbolized[:invocation_id],
            provider_name: symbolized[:provider_name],
            deadline_seconds: symbolized[:deadline_seconds],
            elapsed_seconds: symbolized[:elapsed_seconds],
            exit_status: symbolized[:exit_status],
            signal: symbolized[:signal],
            execution_began: symbolized.fetch(:execution_began, true),
            stdout_excerpt: symbolized[:stdout_excerpt],
            stderr_excerpt: symbolized[:stderr_excerpt]
          )
        end

        # True when the provider process was spawned and its final state is not
        # a confirmed successful completion. Such sessions may have performed
        # side effects; callers must not replay them automatically.
        def uncertain_execution?
          execution_began
        end

        # First bounded diagnostic line from the captured streams, for
        # actionable terminal messages. Prefers stderr; falls back to stdout.
        # @return [String, nil]
        def detail_line
          source = [stderr_excerpt, stdout_excerpt].compact
            .map { |stream| stream.lines.map(&:strip) }
            .flatten
            .reject(&:empty?)
            .first.to_s
          return nil if source.empty?

          source.length > 300 ? "#{source[0, 300]}…[truncated]" : source
        end

        # Human-readable one-line summary safe for reports and error messages.
        # @return [String]
        def summary
          parts = [outcome_label]
          parts << "elapsed #{format_seconds(elapsed_seconds)}" if elapsed_seconds
          parts << "deadline #{format_seconds(deadline_seconds)}" if deadline_seconds
          parts << "exit #{exit_status}" unless exit_status.nil?
          parts << "signal #{signal}" if signal
          parts << "invocation #{invocation_id}" if invocation_id
          parts.join(", ")
        end

        # @return [Hash] plain hash without output excerpts (for metadata surfaces)
        def to_h
          {
            outcome: outcome,
            invocation_id: invocation_id,
            provider_name: provider_name,
            deadline_seconds: deadline_seconds,
            elapsed_seconds: elapsed_seconds,
            exit_status: exit_status,
            signal: signal,
            execution_began: execution_began
          }.compact
        end

        private

        def outcome_label
          case outcome
          when :deadline_exceeded then "deadline_exceeded"
          when :transport_failure then "transport_failure"
          when :nonzero_exit then "nonzero_exit"
          when :no_response then "completed_without_final_response"
          end
        end

        def format_seconds(value)
          return value.to_s if value.is_a?(String)

          format("%.1fs", value)
        end

        def bounded_excerpt(text)
          return nil if text.nil?

          excerpt = text.to_s
          excerpt = "#{excerpt[0, EXCERPT_LIMIT]}…[truncated]" if excerpt.length > EXCERPT_LIMIT
          excerpt.freeze
        end
      end
    end
  end
end
