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
          AMBIENT_TMUX_ENV_VARS = %w[TMUX TMUX_PANE].freeze
          BUNDLER_ENV_PREFIXES = %w[BUNDLE BUNDLER].freeze
          STRIPPED_ENV_KEYS = %w[RUBYOPT RUBYLIB].freeze
          RESERVED_ENV_KEYS = Molecules::SandboxRuntimeBuilder::RESERVED_ENV_KEYS + %w[
            PATH HOME TMPDIR XDG_RUNTIME_DIR TMUX_TMPDIR ACE_TMUX_SESSION
          ]

          def initialize(command_runner: nil, system_runner: nil, time_source: nil, sandbox_backend: nil)
            @command_runner = command_runner || method(:capture3)
            @system_runner = system_runner || method(:system)
            @time_source = time_source || -> { Time.now.to_i }
            @sandbox_backend = sandbox_backend
          end

          # Execute all setup steps in a sandbox directory
          #
          # @param setup_steps [Array] Setup steps from scenario.yml
          # @param sandbox_dir [String] Path to the sandbox directory
          # @param fixture_source [String, nil] Path to the fixtures/ directory
          # @param scenario_name [String, nil] Test ID for tmux session naming (e.g., "TS-OVERSEER-001")
          # @param run_id [String, nil] Unique run ID for deterministic tmux session naming
          # @return [Hash] Result with :success, :steps_completed, :error, :env, :tmux_session keys
          def execute(setup_steps:, sandbox_dir:, fixture_source: nil, scenario_name: nil, run_id: nil, initial_env: {},
            git_excludes: [])
            FileUtils.mkdir_p(sandbox_dir)
            env = if @sandbox_backend
              @sandbox_backend.prepared_env(initial_env.dup)
            else
              initial_env.dup
            end
            @git_excludes = normalize_git_excludes(git_excludes)
            steps_completed = 0
            @tmux_session = nil
            @scenario_name = scenario_name
            @run_id = run_id
            @teardown_env = nil

            setup_steps.each do |step|
              execute_step(step, sandbox_dir, env, fixture_source)
              steps_completed += 1
            end

            {
              success: true,
              steps_completed: steps_completed,
              error: nil,
              env: merged_environment(env),
              tmux_session: @tmux_session
            }
          rescue => e
            {
              success: false,
              steps_completed: steps_completed,
              error: e.message,
              env: merged_environment(env),
              tmux_session: @tmux_session
            }
          end

          # Clean up resources created during setup (e.g. tmux session)
          def teardown
            return unless @tmux_session

            if @sandbox_backend
              @sandbox_backend.capture3(
                ["tmux", "kill-session", "-t", @tmux_session],
                chdir: @teardown_env&.fetch("PROJECT_ROOT_PATH", Dir.pwd) || Dir.pwd,
                env: @teardown_env || {}
              )
            else
              @system_runner.call("tmux", "kill-session", "-t", @tmux_session, out: File::NULL, err: File::NULL)
            end
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
            tmux_env = merged_environment(env).merge("TMUX_TMPDIR" => env["TMUX_TMPDIR"].to_s.empty? ? nil : env["TMUX_TMPDIR"])
            if @sandbox_backend
              _stdout, stderr, status = @sandbox_backend.capture3(
                ["tmux", "new-session", "-d", "-s", session_name],
                chdir: env["PROJECT_ROOT_PATH"] || Dir.pwd,
                env: tmux_env
              )
            else
              _stdout, stderr, status = @command_runner.call(tmux_env, "tmux", "new-session", "-d", "-s", session_name)
            end
            raise "Failed to create tmux session '#{session_name}': #{stderr.strip}" unless status.success?

            @tmux_session = session_name
            env["ACE_TMUX_SESSION"] = session_name
            @teardown_env = merged_environment(env)
          end

          # Initialize a git repo with test user config
          def handle_git_init(sandbox_dir, env)
            run_command("git", "init", "-b", "main", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.name", "Test User", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.email", "test@example.com", chdir: sandbox_dir, env: env)
            seed_git_excludes(sandbox_dir)
          end

          # Copy fixture files into sandbox
          def handle_copy_fixtures(sandbox_dir, fixture_source)
            raise ArgumentError, "No fixture source provided for copy-fixtures step" if fixture_source.nil?

            FixtureCopier.new.copy(source_dir: fixture_source, target_dir: sandbox_dir)
          end

          # Execute a shell command in the sandbox
          # NOTE: Uses shell invocation intentionally to support shell operators
          # (&&, |, >) in scenario.yml setup steps. Commands originate from
          # committed scenario.yml files, not user input, so shell injection risk is mitigated.
          # We explicitly disable profile/rc loading to keep sandbox env authoritative.
          def handle_run(command, sandbox_dir, env)
            full_env = merged_environment(env)
            # Re-export env vars inside the command to keep explicit sandbox
            # values authoritative across compound shell expressions.
            export_vars = env.dup
            %w[PROJECT_ROOT_PATH].each do |key|
              export_vars[key] ||= ENV[key] if ENV[key]
            end
            exports = export_vars.map { |k, v| "export #{k}=#{Shellwords.shellescape(v.to_s)}" }.join("; ")
            wrapped = exports.empty? ? command : "#{exports}; #{command}"
            stdout, stderr, status = if @sandbox_backend
              @sandbox_backend.capture3(["bash", "--noprofile", "--norc", "-c", wrapped], chdir: sandbox_dir, env: full_env)
            else
              Open3.capture3(full_env, "bash", "--noprofile", "--norc", "-c", wrapped, chdir: sandbox_dir)
            end

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
            vars.each do |k, v|
              key = k.to_s
              next if RESERVED_ENV_KEYS.include?(key)

              env[key] = v.to_s
            end
          end

          # Merge custom env vars with the process environment
          #
          # @param env [Hash] Custom environment variables
          # @return [Hash] Merged environment
          def merged_environment(env)
            base_env = sanitized_process_environment
            return base_env if env.empty?

            base_env.merge(env.transform_keys(&:to_s))
          end

          # Run a command and raise on failure
          def run_command(*args, chdir:, env: {})
            merged_env = merged_environment(env)
            _stdout, stderr, status = if @sandbox_backend
              @sandbox_backend.capture3(args, chdir: chdir, env: merged_env)
            else
              @command_runner.call(merged_env, *args, chdir: chdir)
            end

            unless status.success?
              raise "Command failed (exit #{status.exitstatus}): #{args.join(" ")}\n#{stderr}"
            end
          end

          def capture3(*args, **kwargs)
            Open3.capture3(*args, **kwargs)
          end

          def seed_git_excludes(sandbox_dir)
            patterns = (default_git_excludes + @git_excludes).uniq
            return if patterns.empty?

            exclude_path = File.join(sandbox_dir, ".git", "info", "exclude")
            existing = File.exist?(exclude_path) ? File.readlines(exclude_path, chomp: true) : []
            additions = patterns.reject { |pattern| existing.include?(pattern) }
            return if additions.empty?

            File.write(exclude_path, (existing + additions).join("\n") + "\n")
          end

          def normalize_git_excludes(git_excludes)
            Array(git_excludes).map(&:to_s).map(&:strip).reject(&:empty?).uniq
          end

          def default_git_excludes
            [".ace-local/", "reports/", "results/"]
          end

          def sanitized_process_environment
            ENV.to_h.each_with_object({}) do |(key, value), env|
              if AMBIENT_TMUX_ENV_VARS.include?(key) || STRIPPED_ENV_KEYS.include?(key) ||
                  BUNDLER_ENV_PREFIXES.any? { |prefix| key.start_with?(prefix) }
                env[key] = nil
                next
              end

              env[key] = value
            end
          end
        end
      end
    end
  end
end
