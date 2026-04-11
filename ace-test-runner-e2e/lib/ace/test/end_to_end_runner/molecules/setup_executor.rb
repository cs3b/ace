# frozen_string_literal: true

require "fileutils"
require "open3"
require "shellwords"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes setup steps deterministically to create a populated sandbox
        #
        # Processes the setup array from scenario.yml, running each action
        # via Ruby system calls (no LLM involved). Supports: git-init,
        # copy-fixtures, run, write-file, agent-env, and tmux-session actions.
        #
        # Note: This is a Molecule because it performs filesystem I/O and
        # system calls via Open3 and FileUtils.
        class SetupExecutor
          def initialize(command_runner: nil, system_runner: nil, time_source: nil)
            @command_runner = command_runner || method(:capture3)
            @system_runner = system_runner || method(:system)
            @time_source = time_source || -> { Time.now.to_i }
          end

          # Execute all setup steps in a sandbox directory
          #
          # @param setup_steps [Array] Setup steps from scenario.yml
          # @param sandbox_dir [String] Path to the sandbox directory
          # @param fixture_source [String, nil] Path to the fixtures/ directory
          # @param scenario_name [String, nil] Test ID for tmux session naming (e.g., "TS-OVERSEER-001")
          # @param run_id [String, nil] Unique run ID for deterministic tmux session naming
          # @return [Hash] Result with :success, :steps_completed, :error, :env, :tmux_session keys
          def execute(setup_steps:, sandbox_dir:, fixture_source: nil, scenario_name: nil, run_id: nil, initial_env: {})
            FileUtils.mkdir_p(sandbox_dir)
            env = initial_env.dup
            steps_completed = 0
            @tmux_session = nil
            @scenario_name = scenario_name
            @run_id = run_id

            setup_steps.each do |step|
              execute_step(step, sandbox_dir, env, fixture_source)
              steps_completed += 1
            end

            {success: true, steps_completed: steps_completed, error: nil, env: env, tmux_session: @tmux_session}
          rescue => e
            {success: false, steps_completed: steps_completed, error: e.message, env: env, tmux_session: @tmux_session}
          end

          # Clean up resources created during setup (e.g. tmux session)
          def teardown
            return unless @tmux_session

            @system_runner.call("tmux", "kill-session", "-t", @tmux_session, out: File::NULL, err: File::NULL)
            @tmux_session = nil
          end

          private

          # Dispatch a single step to the appropriate handler
          #
          # @param step [String, Hash] Step definition
          # @param sandbox_dir [String] Sandbox path
          # @param env [Hash] Environment variables
          # @param fixture_source [String, nil] Fixtures path
          def execute_step(step, sandbox_dir, env, fixture_source)
            case step
            when "git-init"
              handle_git_init(sandbox_dir, env)
            when "copy-fixtures"
              handle_copy_fixtures(sandbox_dir, fixture_source)
            when "tmux-session"
              handle_tmux_session(env)
            when Hash
              execute_hash_step(step, sandbox_dir, env)
            else
              raise ArgumentError, "Unknown setup step: #{step.inspect}"
            end
          end

          # Dispatch hash-based steps
          def execute_hash_step(step, sandbox_dir, env)
            key = step.keys.first
            value = step.values.first

            case key
            when "run"
              handle_run(value, sandbox_dir, env)
            when "write-file"
              handle_write_file(value["path"], value["content"], sandbox_dir)
            when "agent-env"
              handle_env(value, env)
            when "tmux-session"
              handle_tmux_session(env, value)
            else
              raise ArgumentError, "Unknown setup step type: #{key.inspect}"
            end
          end

          # Create an isolated detached tmux session and store its name in env
          def handle_tmux_session(env, config = nil)
            name_source = config.is_a?(Hash) ? config["name-source"] : nil
            session_name = if name_source == "run-id" && @run_id && !@run_id.to_s.empty?
              @run_id
            else
              @scenario_name ? "#{@scenario_name}-e2e" : "ace-e2e-#{@time_source.call}"
            end
            _stdout, stderr, status = @command_runner.call("tmux", "new-session", "-d", "-s", session_name)
            raise "Failed to create tmux session '#{session_name}': #{stderr.strip}" unless status.success?

            @tmux_session = session_name
            env["ACE_TMUX_SESSION"] = session_name
          end

          # Initialize a git repo with test user config
          def handle_git_init(sandbox_dir, env)
            run_command("git", "init", "-b", "main", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.name", "Test User", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.email", "test@example.com", chdir: sandbox_dir, env: env)
          end

          # Copy fixture files into sandbox
          def handle_copy_fixtures(sandbox_dir, fixture_source)
            raise ArgumentError, "No fixture source provided for copy-fixtures step" if fixture_source.nil?

            FixtureCopier.new.copy(source_dir: fixture_source, target_dir: sandbox_dir)
          end

          # Execute a shell command in the sandbox
          # NOTE: Uses shell invocation (bash -lc) intentionally to support
          # shell operators (&&, |, >) in scenario.yml setup steps. Commands originate from
          # committed scenario.yml files, not user input, so shell injection risk is mitigated.
          def handle_run(command, sandbox_dir, env)
            full_env = merged_environment(env)
            # Re-export env vars after profile sourcing to protect against
            # mise's shell hook clobbering.
            export_vars = env.dup
            %w[PROJECT_ROOT_PATH].each do |key|
              export_vars[key] ||= ENV[key] if ENV[key]
            end
            exports = export_vars.map { |k, v| "export #{k}=#{Shellwords.shellescape(v.to_s)}" }.join("; ")
            wrapped = exports.empty? ? command : "#{exports}; #{command}"
            stdout, stderr, status = Open3.capture3(full_env, "bash", "-lc", wrapped, chdir: sandbox_dir)

            unless status.success?
              raise "Setup step 'run' failed (exit #{status.exitstatus}): #{command}\n#{stderr}"
            end

            stdout
          end

          # Write inline content to a file in the sandbox
          def handle_write_file(path, content, sandbox_dir)
            full_path = File.join(sandbox_dir, path)
            FileUtils.mkdir_p(File.dirname(full_path))
            File.write(full_path, content)
          end

          # Merge environment variables for subsequent steps
          def handle_env(vars, env)
            vars.each { |k, v| env[k.to_s] = v.to_s }
          end

          # Merge custom env vars with the process environment
          #
          # @param env [Hash] Custom environment variables
          # @return [Hash] Merged environment
          def merged_environment(env)
            return ENV.to_h if env.empty?
            ENV.to_h.merge(env.transform_keys(&:to_s))
          end

          # Run a command and raise on failure
          def run_command(*args, chdir:, env: {})
            _stdout, stderr, status = @command_runner.call(merged_environment(env), *args, chdir: chdir)

            unless status.success?
              raise "Command failed (exit #{status.exitstatus}): #{args.join(" ")}\n#{stderr}"
            end
          end

          def capture3(*args, **kwargs)
            Open3.capture3(*args, **kwargs)
          end
        end
      end
    end
  end
end
