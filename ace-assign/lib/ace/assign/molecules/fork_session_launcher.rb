# frozen_string_literal: true

require "ace/llm"
require "fileutils"

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
        DEFAULT_TARGET_ENV = "ACE_ASSIGN_DEFAULT_TARGET"
        CURRENT_ASSIGNMENT_ID_ENV = "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID"
        CURRENT_FORK_ROOT_ENV = "ACE_ASSIGN_CURRENT_FORK_ROOT"

        def self.fork_scope_env(assignment_id:, fork_root:)
          scoped_target = "#{assignment_id}@#{fork_root}"
          {
            DEFAULT_TARGET_ENV => scoped_target,
            CURRENT_ASSIGNMENT_ID_ENV => assignment_id.to_s,
            CURRENT_FORK_ROOT_ENV => fork_root.to_s
          }
        end

        def self.same_scoped_refork?(assignment_id:, fork_root:, env: ENV)
          assignment_ref = assignment_id.to_s.strip
          root_ref = fork_root.to_s.strip
          return false if assignment_ref.empty? || root_ref.empty?

          env[CURRENT_ASSIGNMENT_ID_ENV].to_s.strip == assignment_ref &&
            env[CURRENT_FORK_ROOT_ENV].to_s.strip == root_ref
        end

        def initialize(config: nil, query_interface: Ace::LLM::QueryInterface, tmux_runner: nil, interactive_builder: nil)
          @config = config || Ace::Assign.config
          @query_interface = query_interface
          @tmux_runner = tmux_runner || TmuxControlSurfaceRunner.new
          @interactive_builder = interactive_builder || Ace::LLM::Molecules::InteractiveCommandBuilder.new
        end

        def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil, cache_dir: nil, launch_mode: nil, callback_pane: nil)
          ensure_not_same_scoped_refork!(assignment_id: assignment_id, fork_root: fork_root)
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
              cache_dir: cache_dir,
              callback_pane: callback_pane
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

        def callback_pane
          tmux_runner.current_pane
        end

        def launch_provider_session(assignment_id:, fork_root:, provider:, cli_args: nil, timeout: nil, cache_dir: nil,
          last_message_file: nil, session_meta_file: nil)
          ensure_not_same_scoped_refork!(assignment_id: assignment_id, fork_root: fork_root)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          scoped_assignment = "#{assignment_id}@#{fork_root}"
          prompt = "/as-assign-drive #{scoped_assignment}"
          last_msg_file = last_message_file || build_last_message_file(cache_dir, fork_root)
          scope_env = self.class.fork_scope_env(assignment_id: assignment_id, fork_root: fork_root)

          result = query_interface.query(
            resolved_provider,
            prompt,
            system: nil,
            cli_args: cli_args,
            timeout: resolved_timeout,
            fallback: false,
            last_message_file: last_msg_file,
            subprocess_env: scope_env
          )

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
          mode = config.dig("execution", "launch_mode").to_s.strip if mode.empty?
          mode = DEFAULT_LAUNCH_MODE if mode.empty?
          unless VALID_LAUNCH_MODES.include?(mode)
            raise Error, "Invalid launch mode '#{mode}'. Expected one of: #{VALID_LAUNCH_MODES.join(', ')}"
          end

          return mode unless mode == "auto"

          tmux_runner.tmux_context? ? "tmux" : "headless"
        end

        def launch_tmux(assignment_id:, fork_root:, provider:, cli_args:, timeout:, cache_dir:, callback_pane: nil)
          ensure_not_same_scoped_refork!(assignment_id: assignment_id, fork_root: fork_root)
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
            window_target: window_info[:target],
            root: Dir.pwd,
            keep_existing: window_info[:created]
          )

          session_meta_file = build_session_meta_file(cache_dir, fork_root)
          prompt = "/as-assign-drive #{assignment_id}@#{fork_root}"
          tmux_env = tmux_subprocess_env(
            assignment_id: assignment_id,
            fork_root: fork_root,
            session: session,
            fork_window: fork_window,
            callback_pane: callback_pane
          )
          invocation = interactive_builder.build(
            provider_model: provider,
            prompt: prompt,
            cli_args: cli_args,
            working_dir: Dir.pwd,
            subprocess_env: tmux_env
          )

          tmux_runner.run_invocation_in_pane(
            pane_target: pane_target,
            command: invocation[:command],
            env: invocation[:env],
            working_dir: invocation[:working_dir],
            visible_handoff: invocation[:prompt]
          )
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
            pane: pane_target,
            window_id: window_info[:window_id],
            callback_pane: callback_pane
          )

          return {tmux: true, pane_target: pane_target, callback_mode: true, callback_pane: callback_pane} if callback_pane

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

        def ensure_not_same_scoped_refork!(assignment_id:, fork_root:)
          return unless self.class.same_scoped_refork?(assignment_id: assignment_id, fork_root: fork_root)

          raise Error,
            "Cannot fork-run subtree #{assignment_id}@#{fork_root}: already running inside that scoped subtree. Continue inline instead of calling fork-run again."
        end

        def tmux_subprocess_env(assignment_id:, fork_root:, session:, fork_window:, callback_pane: nil)
          env = self.class.fork_scope_env(assignment_id: assignment_id, fork_root: fork_root).merge(
            "PROJECT_ROOT_PATH" => Dir.pwd,
            "ACE_TMUX_SESSION" => session,
            "ACE_ASSIGN_LAUNCH_MODE" => "tmux",
            "ACE_ASSIGN_FORK_WINDOW" => fork_window
          )
          env["ACE_ASSIGN_CALLBACK_PANE"] = callback_pane if callback_pane && !callback_pane.empty?
          env
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
