# frozen_string_literal: true

require "ace/llm"
require "fileutils"

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
        # @param cache_dir [String, nil] Assignment cache directory for last-message capture
        # @return [Hash] QueryInterface response
        def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil, cache_dir: nil)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          merged_cli_args = merge_cli_args(required_cli_args_for(resolved_provider), cli_args)
          scoped_assignment = "#{assignment_id}@#{fork_root}"
          last_msg_file = build_last_message_file(cache_dir, fork_root)

          result = query_interface.query(
            resolved_provider,
            "/ace-assign-drive #{scoped_assignment}",
            system: nil,
            cli_args: merged_cli_args,
            timeout: resolved_timeout,
            fallback: false,
            last_message_file: last_msg_file
          )

          # Layer 1 write: capture last message for non-Codex providers (or when Codex didn't write).
          # Safety: `query` blocks until the subprocess exits, so by this point Layer 2 (Codex
          # --output-last-message) has already finished writing. No other writer exists at this point.
          if last_msg_file && result[:text] && !result[:text].strip.empty?
            existing = File.exist?(last_msg_file) ? File.read(last_msg_file).strip : ""
            File.write(last_msg_file, result[:text]) if existing.empty?
          end

          write_session_metadata(last_msg_file, result, prompt: "/ace-assign-drive #{scoped_assignment}")

          result
        rescue Ace::LLM::Error => e
          raise Error, "Fork session execution failed via #{resolved_provider}: #{e.message}"
        end

        private

        attr_reader :config, :query_interface

        def write_session_metadata(last_msg_file, result, prompt:)
          return unless last_msg_file

          session_id = result.dig(:metadata, :session_id)

          if session_id.nil? || session_id.to_s.strip.empty?
            detected = detect_provider_session(result[:provider], prompt)
            session_id = detected&.dig(:session_id)
          end

          session_meta_file = last_msg_file.sub(/-last-message\.md$/, "-session.yml")
          meta = {
            "session_id" => session_id,
            "provider" => result[:provider],
            "model" => result[:model],
            "completed_at" => Time.now.utc.iso8601
          }.compact
          File.write(session_meta_file, meta.to_yaml) unless meta.empty?
        end

        def detect_provider_session(provider, prompt)
          require "ace/llm/providers/cli/molecules/session_finder"
          Ace::LLM::Providers::CLI::Molecules::SessionFinder.call(
            provider: provider, working_dir: Dir.pwd, prompt: prompt
          )
        rescue LoadError, StandardError
          nil
        end

        def build_last_message_file(cache_dir, fork_root)
          return nil unless cache_dir

          sessions_dir = File.join(cache_dir, "sessions")
          FileUtils.mkdir_p(sessions_dir)
          File.join(sessions_dir, "#{fork_root}-last-message.md")
        end

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
