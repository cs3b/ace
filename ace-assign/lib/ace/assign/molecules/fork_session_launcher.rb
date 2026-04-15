# frozen_string_literal: true

require "ace/llm"
require "fileutils"
require "rbconfig"
require "shellwords"

module Ace
  module Assign
    module Molecules
      # Launches a forked assignment-driving session via CLI LLM providers.
      class ForkSessionLauncher
        DEFAULT_PROVIDER = "claude:sonnet"
        DEFAULT_TIMEOUT = 1800
        DEFAULT_LAUNCH_MODE = "auto"
        VALID_LAUNCH_MODES = %w[auto headless tmux].freeze
        TMUX_POLL_INTERVAL = 0.5

        def initialize(config: nil, query_interface: Ace::LLM::QueryInterface, tmux_runner: nil, interactive_builder: nil)
          @config = config || Ace::Assign.config
          @query_interface = query_interface
          @tmux_runner = tmux_runner || TmuxForkRunner.new
          @interactive_builder = interactive_builder || Ace::LLM::Molecules::InteractiveCommandBuilder.new
        end

        # Launch forked subtree execution synchronously.
        #
        # @param assignment_id [String] Assignment identifier
        # @param fork_root [String] Subtree root step number
        # @param provider [String, nil] Optional provider override
        # @param cli_args [String, nil] Optional provider CLI args
        # @param timeout [Integer, nil] Optional timeout override (seconds)
        # @param cache_dir [String, nil] Assignment cache directory for last-message capture
        # @param launch_mode [String, nil] Launch mode override (auto|headless|tmux)
        # @return [Hash] QueryInterface response
        def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil, cache_dir: nil, launch_mode: nil)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          resolved_mode = resolve_launch_mode(launch_mode)

          if resolved_mode == "tmux"
            launch_tmux(
              assignment_id: assignment_id,
              fork_root: fork_root,
              provider: resolved_provider,
              cli_args: cli_args,
              timeout: resolved_timeout,
              cache_dir: cache_dir
            )
          else
            launch_provider_session(
              assignment_id: assignment_id,
              fork_root: fork_root,
              provider: resolved_provider,
              cli_args: cli_args,
              timeout: resolved_timeout,
              cache_dir: cache_dir
            )
          end
        end

        def launch_provider_session(assignment_id:, fork_root:, provider:, cli_args: nil, timeout: nil, cache_dir: nil,
          last_message_file: nil, session_meta_file: nil)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          scoped_assignment = "#{assignment_id}@#{fork_root}"
          prompt = "/as-assign-drive #{scoped_assignment}"
          last_msg_file = last_message_file || build_last_message_file(cache_dir, fork_root)

          result = query_interface.query(
            resolved_provider,
            prompt,
            system: nil,
            cli_args: cli_args,
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

          write_session_metadata(last_msg_file, result, prompt: prompt, session_meta_file: session_meta_file)

          result
        rescue Ace::LLM::Error => e
          raise Error, "Fork session execution failed via #{resolved_provider}: #{e.message}"
        end

        private

        attr_reader :config, :query_interface, :tmux_runner, :interactive_builder

        def resolve_launch_mode(explicit_mode)
          mode = explicit_mode.to_s.strip
          mode = DEFAULT_LAUNCH_MODE if mode.empty?
          unless VALID_LAUNCH_MODES.include?(mode)
            raise Error, "Invalid launch mode '#{mode}'. Expected one of: #{VALID_LAUNCH_MODES.join(', ')}"
          end

          return mode unless mode == "auto"

          tmux_runner.tmux_context? ? "tmux" : "headless"
        end

        def launch_tmux(assignment_id:, fork_root:, provider:, cli_args:, timeout:, cache_dir:)
          session = tmux_runner.current_session
          raise Error, "Launch mode tmux requires an active tmux session (TMUX or ACE_TMUX_SESSION)." unless session
          raise Error, "Tmux launch requires assignment cache_dir for subtree polling." if cache_dir.to_s.strip.empty?

          current_window = tmux_runner.current_window
          raise Error, "Could not resolve current tmux window for fork launch." if current_window.to_s.strip.empty?

          fork_window = ENV["ACE_ASSIGN_FORK_WINDOW"].to_s.strip
          fork_window = tmux_runner.fork_window_name(current_window) if fork_window.empty?

          window_info = tmux_runner.ensure_window(session: session, name: fork_window, root: Dir.pwd)
          pane_target = tmux_runner.prepare_pane(
            session: session,
            window: fork_window,
            root: Dir.pwd,
            keep_existing: window_info[:created]
          )

          session_meta_file = build_session_meta_file(cache_dir, fork_root)
          prompt = "/as-assign-drive #{assignment_id}@#{fork_root}"
          invocation = interactive_builder.build(
            provider_model: provider,
            prompt: prompt,
            cli_args: cli_args
          )
          script_path = build_tmux_wrapper(
            assignment_id: assignment_id,
            fork_root: fork_root,
            provider: provider,
            cli_args: cli_args,
            timeout: timeout,
            session_meta_file: session_meta_file,
            session: session,
            fork_window: fork_window,
            visible_handoff: invocation[:prompt]
          )

          tmux_runner.run_script_in_pane(pane_target: pane_target, script_path: script_path)
          tmux_runner.select_window(session: session, window: fork_window) if window_info[:created] && current_window != fork_window
          write_tmux_launch_metadata(
            session_meta_file: session_meta_file,
            provider: invocation[:provider],
            model: invocation[:model],
            prompt: invocation[:prompt]
          )
          tmux_runner.merge_tmux_metadata(
            session_meta_file: session_meta_file,
            session: session,
            window: fork_window,
            pane: pane_target
          )
          wait_for_subtree_terminal(
            assignment_id: assignment_id,
            fork_root: fork_root,
            cache_dir: cache_dir,
            timeout: timeout
          )

          {tmux: true, pane_target: pane_target}
        end

        def write_tmux_launch_metadata(session_meta_file:, provider:, model:, prompt:)
          detected = detect_provider_session(provider, prompt)
          meta = {}
          meta = YAML.safe_load_file(session_meta_file) || {} if File.exist?(session_meta_file)
          meta["provider"] ||= provider
          meta["model"] ||= model
          meta["session_id"] ||= detected&.dig(:session_id)
          meta["launched_at"] ||= Time.now.utc.iso8601
          File.write(session_meta_file, meta.to_yaml) unless meta.empty?
        end

        def write_session_metadata(last_msg_file, result, prompt:, session_meta_file: nil)
          return unless last_msg_file

          session_id = result.dig(:metadata, :session_id)

          if session_id.nil? || session_id.to_s.strip.empty?
            detected = detect_provider_session(result[:provider], prompt)
            session_id = detected&.dig(:session_id)
          end

          session_meta_file ||= last_msg_file.sub(/-last-message\.md$/, "-session.yml")
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

        def build_session_meta_file(cache_dir, fork_root)
          return nil unless cache_dir

          sessions_dir = File.join(cache_dir, "sessions")
          FileUtils.mkdir_p(sessions_dir)
          File.join(sessions_dir, "#{fork_root}-session.yml")
        end

        def build_tmux_wrapper(assignment_id:, fork_root:, provider:, cli_args:, timeout:, session_meta_file:, session:, fork_window:, visible_handoff:)
          sessions_dir = File.dirname(session_meta_file)
          FileUtils.mkdir_p(sessions_dir)
          script_path = File.join(sessions_dir, "#{fork_root}-tmux-launch.sh")

          command = [
            "ace-llm", provider, "/as-assign-drive #{assignment_id}@#{fork_root}",
            "--interactive"
          ]
          command.concat(["--cli-args", cli_args]) if cli_args && !cli_args.strip.empty?

          script = <<~BASH
            #!/usr/bin/env bash
            set -uo pipefail
            cd #{Shellwords.escape(Dir.pwd)}
            export ACE_TMUX_SESSION=#{Shellwords.escape(session)}
            export ACE_ASSIGN_LAUNCH_MODE=tmux
            export ACE_ASSIGN_FORK_WINDOW=#{Shellwords.escape(fork_window)}
            printf '%s\n' #{Shellwords.escape(visible_handoff.to_s)}
            exec #{command.map { |part| Shellwords.escape(part) }.join(" ")}
          BASH

          File.write(script_path, script)
          FileUtils.chmod(0o755, script_path)
          script_path
        end

        def wait_for_subtree_terminal(assignment_id:, fork_root:, cache_dir:, timeout:)
          assignment = Models::Assignment.new(
            id: assignment_id,
            name: "fork",
            created_at: Time.now.utc,
            source_config: "fork-run",
            cache_dir: cache_dir
          )
          scanner = QueueScanner.new
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_i

          loop do
            state = scanner.scan(assignment.steps_dir, assignment: assignment)
            return state if state.subtree_complete?(fork_root)
            raise Error, "Fork session execution failed in tmux subtree #{fork_root}." if state.subtree_failed?(fork_root)

            if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
              raise Error, "Timed out waiting for tmux fork subtree #{fork_root} to reach a terminal state."
            end

            sleep(TMUX_POLL_INTERVAL)
          end
        end
      end
    end
  end
end
