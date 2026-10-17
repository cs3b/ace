# frozen_string_literal: true

require "yaml"
require "date"
require "open3"
require_relative "../atoms/task_id_extractor"
require_relative "../models/task_index"

module Ace
  module Git
    module Worktree
      module Molecules
        # Builds the `.ace-tasks/` task index once per listing run.
        #
        # Scans every task spec (`*.s.md`) under the project's task tree,
        # including special folders such as `_archive/` and `_maybe/`, and reads
        # only the frontmatter (``id`` plus recorded ``worktree`` metadata).
        # Current-tree entries win over archived entries for the same short id.
        class TaskIndexBuilder
          # File glob for task specs under the task root.
          SPEC_GLOB = "**/*.s.md"

          # @param project_root [String, nil] project root (defaults to the git
          #   common-dir parent of the current repository)
          def initialize(project_root: nil)
            @project_root = project_root
          end

          # @return [Models::TaskIndex]
          def build
            root = resolved_project_root
            tasks_root = root ? File.join(root, ".ace-tasks") : nil
            unless tasks_root && Dir.exist?(tasks_root)
              return Models::TaskIndex.new(available: false, project_root: root)
            end

            entries = Dir.glob(File.join(tasks_root, SPEC_GLOB)).filter_map do |spec_path|
              entry_for(spec_path, root)
            end

            Models::TaskIndex.new(entries: deduplicate(entries), available: true, project_root: root)
          end

          private

          # Resolve the project root: the primary working tree that holds
          # `.ace-tasks/`. Uses the git common dir so a linked worktree still
          # reads the project's task tree.
          def resolved_project_root
            return File.expand_path(@project_root) if @project_root

            out, status = Open3.capture2("git", "rev-parse", "--path-format=absolute", "--git-common-dir")
            return Dir.pwd unless status.success?

            common_dir = out.to_s.strip
            return Dir.pwd if common_dir.empty?

            File.dirname(common_dir)
          rescue StandardError
            Dir.pwd
          end

          # @return [Models::TaskIndex::Entry, nil]
          def entry_for(spec_path, root)
            frontmatter = read_frontmatter(spec_path)
            return nil if frontmatter.nil?

            full_id = frontmatter["id"].to_s.strip
            short_id = Atoms::TaskIDExtractor.short_id(full_id) ||
              Atoms::TaskIDExtractor.normalize(full_id)
            return nil if short_id.nil? || short_id.empty? || full_id.empty?

            worktree = frontmatter["worktree"].is_a?(Hash) ? frontmatter["worktree"] : {}
            Models::TaskIndex::Entry.new(
              full_id: full_id,
              short_id: short_id,
              directory: File.dirname(spec_path),
              spec_path: spec_path,
              worktree_path: expand_worktree_path(worktree["path"], root),
              worktree_branch: blank_to_nil(worktree["branch"])
            )
          end

          # @return [Hash, nil] parsed YAML frontmatter
          def read_frontmatter(spec_path)
            content = File.read(spec_path)
            match = content.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)
            return nil unless match

            YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true) || {}
          rescue StandardError
            nil
          end

          def expand_worktree_path(path, root)
            return nil if path.to_s.strip.empty?

            File.expand_path(path.to_s.strip, root)
          end

          def blank_to_nil(value)
            value.to_s.strip.empty? ? nil : value.to_s.strip
          end

          # Keep one entry per short id: the current tree wins over special
          # folders (first path segment starting with "_").
          def deduplicate(entries)
            entries.group_by(&:short_id).map do |_short_id, candidates|
              candidates.min_by { |entry| [archived?(entry) ? 1 : 0, entry.directory] }
            end
          end

          def archived?(entry)
            relative = entry.directory.sub(%r{\A.*/\.ace-tasks/}, "")
            relative.split("/").any? { |segment| segment.start_with?("_") }
          end
        end
      end
    end
  end
end
