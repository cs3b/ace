# frozen_string_literal: true

require "open3"
require "json"
require "yaml"

module Ace
  module Coworker
    module Molecules
      # Reads the executor truth of a worktree: its coworker config
      # (resolved through the coworker config cascade anchored at the
      # probed worktree — the same resolution an `ace-coworker` process
      # running inside that worktree performs, so a commissioned
      # `config_path` such as `.ace-local/coworker/worker.yml` is
      # honored; read leniently) and the assignment inventory via
      # `ace-assign list --all --format json` (subprocess argv contract
      # with explicit cwd, ADR-031).
      class WorktreeExecutorProbe
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(*argv, chdir: cwd) }
        # Coworker config cascade files that may carry a `config_path`
        # override for the probed worktree (project `.ace` and user tiers;
        # the gem-defaults tier equals the loader's built-in default).
        CASCADE_PATTERNS = ["coworker/config.yml", "coworker/config.yaml"].freeze

        attr_reader :project_root

        def initialize(project_root:, runner: DEFAULT_RUNNER)
          @project_root = project_root
          @runner = runner
        end

        # Probes one worktree. Never returns errors: an unreadable config is
        # reported as Atoms::ActiveExecutorRule::UNPARSEABLE; operational
        # failures (missing ace-assign CLI, failed listing, unparseable
        # output) raise Error instead.
        #
        # @return [Hash] {config: Hash | nil | Atoms::ActiveExecutorRule::UNPARSEABLE,
        #   assignments: Array<Hash{"id","name","state","progress"}>}
        # @raise [Error] when the assignment inventory cannot be read
        def probe(worktree_path)
          {
            config: read_config(worktree_path),
            assignments: list_assignments(worktree_path)
          }
        end

        private

        def read_config(worktree_path)
          path = Molecules::ConfigLoader.new(
            project_root: worktree_path,
            defaults: cascade_defaults(worktree_path)
          ).config_path
          return nil unless File.file?(path)

          begin
            raw = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::SyntaxError, StandardError
            return Atoms::ActiveExecutorRule::UNPARSEABLE
          end
          raw.is_a?(Hash) ? raw : Atoms::ActiveExecutorRule::UNPARSEABLE
        end

        # Merge the coworker config cascade anchored at the probed
        # worktree (project `.ace` tiers from the worktree up to its root,
        # then the user tier) — the same file set and order
        # ConfigResolver#resolve_file uses, restricted to the tiers that
        # can override `config_path`. An unreadable cascade falls back to
        # the loader's default config location.
        def cascade_defaults(worktree_path)
          finder = Ace::Support::Config::Molecules::ConfigFinder.new(
            file_patterns: CASCADE_PATTERNS, start_path: worktree_path)
          layers = finder.find_all.select(&:exists).map(&:path)
          layers.reverse.reduce({}) do |merged, path|
            data = Ace::Support::Config::Molecules::YamlLoader.load_file(path).data
            merged.is_a?(Hash) && data.is_a?(Hash) ?
              Ace::Support::Config::Atoms::DeepMerger.merge(merged, data) : {}
          end
        rescue StandardError
          {}
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
