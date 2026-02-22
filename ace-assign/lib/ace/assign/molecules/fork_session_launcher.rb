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

          with_env(
            "ACE_ASSIGN_ID" => assignment_id,
            "ACE_ASSIGN_FORK_ROOT" => fork_root
          ) do
            query_interface.query(
              resolved_provider,
              "/ace-assign-drive",
              system: nil,
              cli_args: merged_cli_args,
              timeout: resolved_timeout,
              fallback: false
            )
          end
        rescue Ace::LLM::Error => e
          raise Error, "Fork session execution failed via #{resolved_provider}: #{e.message}"
        end

        private

        attr_reader :config, :query_interface

        def required_cli_args_for(provider_model)
          provider = provider_model.to_s.split(":").first
          config.dig("providers", "cli_args", provider)
        end

        def merge_cli_args(required, user_provided)
          parts = [required, user_provided].compact.map(&:to_s).map(&:strip).reject(&:empty?)
          return nil if parts.empty?

          parts.join(" ")
        end

        def with_env(vars)
          original = {}
          vars.each do |key, value|
            original[key] = ENV[key]
            ENV[key] = value.to_s
          end
          yield
        ensure
          original.each do |key, value|
            if value.nil?
              ENV.delete(key)
            else
              ENV[key] = value
            end
          end
        end
      end
    end
  end
end
