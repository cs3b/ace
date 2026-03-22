# frozen_string_literal: true

require "fileutils"
require "open3"
require "ace/b36ts"

module Ace
  module Demo
    module Molecules
      class DemoSandboxBuilder
        VALID_SETUP_DIRECTIVES = ["sandbox", "git-init", "copy-fixtures", "run:"].freeze

        def initialize(sandbox_dir: Demo.config["sandbox_dir"], cwd: Dir.pwd)
          @cwd = cwd
          @sandbox_dir = File.expand_path(sandbox_dir || ".ace-local/demo/sandbox", @cwd)
        end

        def build(source_tape_path:, setup_steps:)
          sandbox_id = Ace::B36ts.now
          sandbox_path = File.join(@sandbox_dir, sandbox_id)
          FileUtils.mkdir_p(sandbox_path)

          warnings = []
          setup_steps.each do |step|
            execute_setup_step(
              step,
              sandbox_path: sandbox_path,
              source_tape_path: source_tape_path,
              warnings: warnings
            )
          end

          { id: sandbox_id, path: sandbox_path, warnings: warnings }
        rescue ArgumentError
          cleanup_failed_sandbox(sandbox_path)
          raise
        rescue StandardError => e
          cleanup_failed_sandbox(sandbox_path)
          raise RuntimeError, "Sandbox setup failed for #{sandbox_path}: #{e.message}"
        end

        private

        def execute_setup_step(step, sandbox_path:, source_tape_path:, warnings:)
          case step
          when "sandbox"
            FileUtils.mkdir_p(sandbox_path)
          when "git-init"
            run_command(%w[git init -b main], chdir: sandbox_path)
            run_command(%w[git config user.name Demo User], chdir: sandbox_path)
            run_command(%w[git config user.email demo@example.com], chdir: sandbox_path)
          when "copy-fixtures"
            copy_fixtures(
              source_tape_path: source_tape_path,
              sandbox_path: sandbox_path,
              warnings: warnings
            )
          when Hash
            run = step["run"] || step[:run]
            unless run
              raise ArgumentError, "Unknown setup directive #{step.inspect}. Valid: #{VALID_SETUP_DIRECTIVES.join(', ')}"
            end
            run_shell(run.to_s, chdir: sandbox_path)
          else
            raise ArgumentError, "Unknown setup directive #{step.inspect}. Valid: #{VALID_SETUP_DIRECTIVES.join(', ')}"
          end
        end

        def copy_fixtures(source_tape_path:, sandbox_path:, warnings:)
          if project_tape_path?(source_tape_path)
            warning = "copy-fixtures skipped: source tape is in project .ace/demo/tapes/ (no fixtures root)"
            warnings << warning
            warn warning
            return
          end

          source_dir = File.dirname(source_tape_path)
          fixture_dir = File.join(source_dir, "fixtures")
          unless Dir.exist?(fixture_dir)
            warning = "copy-fixtures skipped: fixtures directory not found at #{fixture_dir}"
            warnings << warning
            warn warning
            return
          end

          Dir.glob(File.join(fixture_dir, "*"), File::FNM_DOTMATCH).each do |entry|
            next if [".", ".."].include?(File.basename(entry))

            FileUtils.cp_r(entry, File.join(sandbox_path, File.basename(entry)))
          end
        end

        def project_tape_path?(tape_path)
          project_tape_root = File.expand_path(File.join(@cwd, ".ace", "demo", "tapes"))
          expanded = File.expand_path(tape_path)
          expanded == project_tape_root || expanded.start_with?("#{project_tape_root}/")
        end

        def run_shell(command, chdir:)
          _stdout, stderr, status = Open3.capture3("bash", "-lc", command, chdir: chdir)
          return if status.success?

          raise RuntimeError, "Setup command failed (exit #{status.exitstatus}): #{command}\n#{stderr}"
        end

        def run_command(args, chdir:)
          _stdout, stderr, status = Open3.capture3(*args, chdir: chdir)
          return if status.success?

          raise RuntimeError, "Setup command failed (exit #{status.exitstatus}): #{args.join(' ')}\n#{stderr}"
        end

        def cleanup_failed_sandbox(sandbox_path)
          return unless sandbox_path && Dir.exist?(sandbox_path)

          FileUtils.rm_rf(sandbox_path)
        end
      end
    end
  end
end
