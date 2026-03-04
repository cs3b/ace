# frozen_string_literal: true

require "ace/llm"

module Ace
  module Assign
    module Molecules
      # Launches a forked assignment-driving session via CLI LLM providers.
      class ForkSessionLauncher
        DEFAULT_PROVIDER = "claude:sonnet".freeze
        DEFAULT_TIMEOUT = 1800

        def initialize(config: nil, query_interface: Ace::LLM::QueryInterface)
          @config = config || Ace::Assign.config
          @query_interface = query_interface
        end

        # Launch forked subtree execution synchronously.
        #
        # @param assignment_id [String] Assignment identifier
        # @param fork_root [String] Subtree root phase number
        # @param provider [String, nil] Optional provider override
        # @param cli_args [String, nil] Optional provider CLI args
        # @param timeout [Integer, nil] Optional timeout override (seconds)
        # @return [Hash] QueryInterface response
        def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          merged_cli_args = merge_cli_args(required_cli_args_for(resolved_provider), cli_args)
          scoped_assignment = "#{assignment_id}@#{fork_root}"

          query_interface.query(
            resolved_provider,
            "/ace-assign-drive #{scoped_assignment}",
            system: nil,
            cli_args: merged_cli_args,
            timeout: resolved_timeout,
            fallback: false
          )
        rescue Ace::LLM::Error => e
          raise Error, "Fork session execution failed via #{resolved_provider}: #{e.message}"
        end

        private

        attr_reader :config, :query_interface

        def required_cli_args_for(provider_model)
          provider = provider_model.to_s.split(":").first
          config.dig("providers", "cli_args", provider)
        end

        # @param required [String, Array<String>, nil] Provider-required args
        # @param user_provided [String, Array<String>, nil] User-provided args
        # @return [String, nil] Merged args string
        def merge_cli_args(required, user_provided)
          parts = [required, user_provided].flat_map { |value| Array(value) }.map(&:to_s).map(&:strip).reject(&:empty?)
          return nil if parts.empty?

          parts.join(" ")
        end
      end
    end
  end
end
