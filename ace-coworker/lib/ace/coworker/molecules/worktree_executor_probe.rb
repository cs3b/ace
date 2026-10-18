# frozen_string_literal: true

require "open3"
require "json"
require "yaml"

module Ace
  module Coworker
    module Molecules
      # Reads the executor truth of a worktree: its coworker config
      # (<worktree>/.ace-local/coworker/config.yml, read leniently) and the
      # assignment inventory via `ace-assign list --all --format json`
      # (subprocess argv contract with explicit cwd, ADR-031).
      class WorktreeExecutorProbe
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(*argv, chdir: cwd) }

        attr_reader :project_root

        def initialize(project_root:, runner: DEFAULT_RUNNER)
          @project_root = project_root
          @runner = runner
        end

        # @return [Hash] {config: Hash | nil | Atoms::ActiveExecutorRule::UNPARSEABLE,
        #   assignments: Array<Hash{"id","name","state","progress"}>, error: String | nil}
        def probe(worktree_path)
          {
            config: read_config(worktree_path),
            assignments: list_assignments(worktree_path)
          }
        end

        private

        def read_config(worktree_path)
          path = File.join(worktree_path, ".ace-local", "coworker", "config.yml")
          return nil unless File.file?(path)

          begin
            raw = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::SyntaxError, StandardError
            return Atoms::ActiveExecutorRule::UNPARSEABLE
          end
          raw.is_a?(Hash) ? raw : Atoms::ActiveExecutorRule::UNPARSEABLE
        end

        def list_assignments(worktree_path)
          argv = [assign_binary, "list", "--all", "--format", "json"]
          begin
            out, err, status = @runner.call(argv, worktree_path)
          rescue Errno::ENOENT
            raise Error, "required CLI '#{assign_binary}' not found; install the ace-assign gem"
          end
          unless status.success?
            message = err.to_s.strip.empty? ? out.to_s.strip : err.to_s.strip
            raise Error, "cannot list assignments in '#{worktree_path}': #{message}"
          end

          begin
            payload = JSON.parse(out)
          rescue JSON::ParserError => e
            raise Error, "cannot parse ace-assign list for '#{worktree_path}': #{e.message}"
          end
          return [] unless payload.is_a?(Array)

          payload.filter_map do |entry|
            next unless entry.is_a?(Hash)

            {"id" => entry["id"].to_s, "name" => entry["name"].to_s,
             "state" => entry["state"].to_s, "progress" => entry["progress"].to_s}
          end
        end

        # Prefer the repo binstub when present (agent shells do not activate
        # mise, so bare ace-* may resolve to stale installed gems); the
        # subprocess still runs with cwd = the probed worktree.
        def assign_binary
          binstub = File.join(@project_root, "bin", "ace-assign")
          File.executable?(binstub) ? binstub : "ace-assign"
        end
      end
    end
  end
end
