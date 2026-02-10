# frozen_string_literal: true

require "fileutils"
require "open3"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes setup steps deterministically to create a populated sandbox
        #
        # Processes the setup array from scenario.yml, running each action
        # via Ruby system calls (no LLM involved). Supports: git-init,
        # copy-fixtures, run, write-file, and env actions.
        #
        # Note: This is a Molecule because it performs filesystem I/O and
        # system calls via Open3 and FileUtils.
        class SetupExecutor
          # Execute all setup steps in a sandbox directory
          #
          # @param setup_steps [Array] Setup steps from scenario.yml
          # @param sandbox_dir [String] Path to the sandbox directory
          # @param fixture_source [String, nil] Path to the fixtures/ directory
          # @return [Hash] Result with :success, :steps_completed, :error keys
          def execute(setup_steps:, sandbox_dir:, fixture_source: nil)
            FileUtils.mkdir_p(sandbox_dir)
            env = {}
            steps_completed = 0

            setup_steps.each do |step|
              execute_step(step, sandbox_dir, env, fixture_source)
              steps_completed += 1
            end

            { success: true, steps_completed: steps_completed, error: nil }
          rescue StandardError => e
            { success: false, steps_completed: steps_completed, error: e.message }
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
            when "env"
              handle_env(value, env)
            else
              raise ArgumentError, "Unknown setup step type: #{key.inspect}"
            end
          end

          # Initialize a git repo with test user config
          def handle_git_init(sandbox_dir, env)
            run_command("git", "init", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.name", "Test User", chdir: sandbox_dir, env: env)
            run_command("git", "config", "user.email", "test@example.com", chdir: sandbox_dir, env: env)
          end

          # Copy fixture files into sandbox
          def handle_copy_fixtures(sandbox_dir, fixture_source)
            raise ArgumentError, "No fixture source provided for copy-fixtures step" if fixture_source.nil?

            FixtureCopier.new.copy(source_dir: fixture_source, target_dir: sandbox_dir)
          end

          # Execute a shell command in the sandbox
          def handle_run(command, sandbox_dir, env)
            merged_env = ENV.to_h.merge(env.transform_keys(&:to_s))
            stdout, stderr, status = Open3.capture3(merged_env, command, chdir: sandbox_dir)

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

          # Run a command and raise on failure
          def run_command(*args, chdir:, env: {})
            merged_env = ENV.to_h.merge(env.transform_keys(&:to_s))
            _stdout, stderr, status = Open3.capture3(merged_env, *args, chdir: chdir)

            unless status.success?
              raise "Command failed (exit #{status.exitstatus}): #{args.join(' ')}\n#{stderr}"
            end
          end
        end
      end
    end
  end
end
