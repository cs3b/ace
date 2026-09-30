# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "shellwords"
require "time"

require_relative "release_manifest"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes setup steps deterministically to create a populated sandbox
        #
        # Processes the setup array from scenario.yml, running each action
        # via Ruby system calls (no LLM involved). Supports: git-init,
        # copy-fixtures, run, write-file, agent-env, tmux-session, and
        # release-manifest actions.
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
          RELEASE_MANIFEST_DEFAULT_PATH = File.join(".ace-local", "release", "installation-manifest.json")
          # Retry trust state lives in the report directory — host-side,
          # outside the runner-writable sandbox. A marker inside the sandbox
          # would let a compromised runner forge reuse state, redirect
          # manifest copies outside the sandbox, or skip revalidation.
          SETUP_STATE_FILE = ".ace-e2e-setup-state.json"
          # Only the sandbox runtime contract is persisted for reuse. The
          # merged setup environment inherits the host process environment,
          # which can carry secrets that must never land in a state file.
          PERSISTED_ENV_KEYS = (
            Molecules::SandboxRuntimeBuilder::RESERVED_ENV_KEYS + %w[
              PATH ACE_E2E_SANDBOX_RUNTIME_ROOT ACE_E2E_SANDBOX_RUBY_VERSION ACE_E2E_SANDBOX_RUBY_ROOT
            ]
          ).freeze

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
          # @param release_manifest_path [String, nil] Explicit absolute manifest path carried
          #   from the invoking process (ACE_RELEASE_MANIFEST). When nil, the release-manifest
          #   step falls back to the default path under ACE_E2E_SOURCE_ROOT.
          # @param state_file [String, nil] Host-side path (report directory) for retry
          #   state. When nil, no retry state is recorded and the sandbox is never reused.
          # @return [Hash] Result with :success, :steps_completed, :error, :env, :tmux_session keys
          def execute(setup_steps:, sandbox_dir:, fixture_source: nil, scenario_name: nil, run_id: nil, initial_env: {},
            git_excludes: [], release_manifest_path: nil, state_file: nil)
            # Initialized before any filesystem operation: an early failure
            # must reach the rescue as a clean setup failure, not as a
            # secondary error from nil state.
            env = {}
            steps_completed = 0
            @tmux_session = nil
            @teardown_env = nil
            FileUtils.mkdir_p(sandbox_dir)
            # A rerun invalidates any earlier success up front: state is
            # recreated only after every step and the persisted env succeed.
            if state_file
              FileUtils.rm_f(state_file)
              # The prior attempt's completion record must never bless a
              # retried run that fails before rewriting it.
              FileUtils.rm_f(File.join(File.dirname(state_file), "metadata.yml"))
            end
            # Prior-attempt goal evidence must never survive into a retried
            # run: the goals rebuild results/ from scratch.
            FileUtils.rm_rf(File.join(sandbox_dir, "results"))
            env = if @sandbox_backend
              @sandbox_backend.prepared_env(initial_env.dup)
            else
              initial_env.dup
            end
            @git_excludes = normalize_git_excludes(git_excludes)
            @release_manifest_input = release_manifest_path
            @release_manifest_state = nil
            steps_completed = 0
            @tmux_session = nil
            @scenario_name = scenario_name
            @run_id = run_id
            @teardown_env = nil

            setup_steps.each do |step|
              execute_step(step, sandbox_dir, env, fixture_source)
              steps_completed += 1
            end
            merged = merged_environment(env)
            if state_file
              FileUtils.mkdir_p(File.dirname(state_file))
              persisted = merged.slice(*PERSISTED_ENV_KEYS).compact
              # The live value may be relative (agent-env PROJECT_ROOT_PATH: .);
              # the persisted contract must be absolute so a reused sandbox is
              # recognized as prepared by the pipeline.
              if persisted["PROJECT_ROOT_PATH"] && !persisted["PROJECT_ROOT_PATH"].start_with?("/")
                persisted["PROJECT_ROOT_PATH"] = File.expand_path(persisted["PROJECT_ROOT_PATH"], sandbox_dir)
              end
              generated_gemfile = File.join(sandbox_dir, "Gemfile")
              source_root = env["ACE_E2E_SOURCE_ROOT"].to_s
              source_gemfile = source_root.empty? ? nil : File.join(source_root, "Gemfile")
              File.write(state_file, JSON.generate({
                "completed_at" => Time.now.utc.iso8601,
                "sandbox_dir" => sandbox_dir,
                "setup_steps" => self.class.normalize_state_steps(setup_steps),
                "release_manifest" => @release_manifest_state,
                "env" => persisted,
                "gemfile" => {
                  # The sandbox Gemfile is derived from the source root's
                  # Gemfile; a retry must regenerate it when either changes.
                  "source_root" => source_root,
                  "source_digest" => source_gemfile && File.file?(source_gemfile) ? Digest::SHA256.file(source_gemfile).hexdigest : nil,
                  "generated_digest" => File.file?(generated_gemfile) ? Digest::SHA256.file(generated_gemfile).hexdigest : nil
                }
              }))
            end

            {
              success: true,
              steps_completed: steps_completed,
              error: nil,
              env: merged,
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
            when "release-manifest"
              handle_release_manifest(value, sandbox_dir, env)
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

          # Validate the frozen release manifest and copy its exact bytes into
          # the sandbox. The source is the explicitly allowed input carried
          # from the invoking process (ACE_RELEASE_MANIFEST, absolute path);
          # without it, the default path under ACE_E2E_SOURCE_ROOT is used.
          # Any missing, unreadable, malformed, or conflicting manifest raises
          # here so setup fails before any install goal can run.
          def handle_release_manifest(config, sandbox_dir, env)
            target = config.is_a?(Hash) ? config["to"] : config
            raise ArgumentError, "release-manifest step requires a target path" if target.to_s.strip.empty?

            required = config.is_a?(Hash) ? Array(config["require"]) : []
            source = release_manifest_source(env)
            # The scenario declares the destination; the copy itself is still
            # confined to the sandbox with no symlinked path components.
            target_path = self.class.validated_manifest_target(sandbox_dir, target)
            raise ArgumentError, "release-manifest target escapes the sandbox: #{target}" unless target_path

            FileUtils.mkdir_p(File.dirname(target_path))
            digest = Molecules::ReleaseManifest.validate_and_copy(
              source_path: source,
              target_path: target_path,
              required_packages: required
            )
            @release_manifest_state = {
              "source" => File.expand_path(source),
              "target" => target,
              "digest" => digest
            }
          end

          def release_manifest_source(env)
            self.class.release_manifest_source_for(env, @release_manifest_input)
          end

          class << self
            # Retry state for a completed setup. Returns nil when there is no
            # usable state (no file, unreadable, from another sandbox, or
            # recorded for different setup steps).
            def setup_state_for(state_file, sandbox_dir, setup_steps: nil)
              return nil unless state_file && File.file?(state_file)

              state = JSON.parse(File.read(state_file))
              return nil unless state.is_a?(Hash)
              return nil unless state["sandbox_dir"] &&
                File.expand_path(state["sandbox_dir"]) == File.expand_path(sandbox_dir)
              return nil if setup_steps && state["setup_steps"] != normalize_state_steps(setup_steps)

              state
            rescue JSON::ParserError, SystemCallError
              nil
            end

            def normalize_state_steps(setup_steps)
              Array(setup_steps).map { |step| step.is_a?(Hash) ? [step.keys.first, step.values.first] : step }
            end

            # The manifest copy destination comes from trusted setup state,
            # but the runner controls the sandbox filesystem in between: a
            # symlinked path component could redirect the host-side write
            # outside the sandbox. Parent components must be real
            # directories; the final component may be an existing regular
            # file (the previous validated copy).
            def validated_manifest_target(sandbox_dir, target)
              sandbox_root = File.expand_path(sandbox_dir)
              # A symlinked sandbox root would redirect every confinement
              # check below it.
              return nil if File.lstat(sandbox_root).symlink?
              relative = target.to_s.split("/")
              current = sandbox_root
              components = relative.reject { |part| part.empty? || part == "." }
              components.each_with_index do |part, index|
                current = File.join(current, part)
                # lstat every component: File.exist? follows symlinks, so a
                # dangling symlink would slip past an existence check and the
                # write would create its target outside the sandbox. ENOENT
                # means the component is genuinely absent (created fresh by
                # mkdir_p); any other stat failure rejects reuse.
                lstat = begin
                  File.lstat(current)
                rescue Errno::ENOENT
                  next
                rescue SystemCallError
                  return nil
                end
                return nil if lstat.symlink?

                last = index == components.size - 1
                if last
                  return nil if lstat.directory?
                elsif !lstat.directory?
                  return nil
                end
              end
              resolved = File.expand_path(current)
              return nil unless resolved.start_with?(sandbox_root + File::SEPARATOR)

              resolved
            rescue SystemCallError
              nil
            end

            # Revalidate the current manifest input against a completed
            # sandbox before it is reused: the validated copy in the sandbox
            # must still match the invoking process's manifest. Returns true
            # when reuse may proceed (no manifest gate recorded, or the
            # current input hashes to the recorded digest); false when the
            # sandbox must be set up again.
            def revalidate_release_manifest(state_file:, sandbox_dir:, explicit: nil, setup_steps: nil)
              state = setup_state_for(state_file, sandbox_dir, setup_steps: setup_steps)
              return false unless state

              recorded = state["release_manifest"]
              return true if recorded.nil?

              target_path = validated_manifest_target(sandbox_dir, recorded["target"])
              return false unless target_path

              source = begin
                release_manifest_source_for(state["env"] || {}, explicit)
              rescue Molecules::ReleaseManifest::Invalid
                return false
              end

              # The source path itself must be the recorded one: an identical
              # copy at a different path would be rejected by finalization's
              # recorded-source binding, so reuse must not accept it either.
              return false unless File.expand_path(source) == File.expand_path(recorded["source"].to_s)

              # Read once: the digest check and the copy must see the same
              # bytes even if the source changes mid-revalidation.
              raw = begin
                File.binread(source)
              rescue SystemCallError
                return false
              end
              return false if Digest::SHA256.hexdigest(raw) != recorded["digest"]

              FileUtils.mkdir_p(File.dirname(target_path))
              File.binwrite(target_path, raw)
              true
            end

            # Retry reuse rebuilds the live environment from the CURRENT
            # process (permitted keys only) and overlays the recorded sandbox
            # runtime paths, so ambient secrets are never restored from the
            # state file while the runtime contract still holds.
            def build_reuse_env(state_env)
              live = ENV.to_h.reject do |key, _value|
                AMBIENT_TMUX_ENV_VARS.include?(key) || STRIPPED_ENV_KEYS.include?(key) ||
                  BUNDLER_ENV_PREFIXES.any? { |prefix| key.start_with?(prefix) } ||
                  key == "ACE_RELEASE_MANIFEST"
              end
              live.merge(state_env || {})
            end

            def release_manifest_source_for(env, explicit)
              explicit = explicit.to_s.strip
              if explicit.empty?
                source_root = env["ACE_E2E_SOURCE_ROOT"].to_s.strip
                if source_root.empty?
                  raise Molecules::ReleaseManifest::Invalid,
                    "no release manifest input and no ACE_E2E_SOURCE_ROOT to derive the default path"
                end
                return File.join(source_root, RELEASE_MANIFEST_DEFAULT_PATH)
              end

              unless explicit.start_with?("/")
                raise Molecules::ReleaseManifest::Invalid,
                  "ACE_RELEASE_MANIFEST must be an absolute JSON file path, got: #{explicit}"
              end

              explicit
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
