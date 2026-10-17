# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Models
        # Immutable index of the current project's tasks, built from the
        # `.ace-tasks/` tree once per listing run.
        #
        # The index maps task spec frontmatter ids (full and short form), task
        # directories, and recorded `worktree.path` / `worktree.branch` metadata
        # so the list command can associate worktrees to tasks without relying
        # on worktree names.
        #
        # @example
        #   index = TaskIndexBuilder.new.build
        #   index.task?("k9y")                                # => true
        #   index.find_by_worktree_branch("codex/k9y-list")   # => Entry
        class TaskIndex
          # One indexed task.
          #
          # @!attribute full_id [String] formatted id (e.g. "8xg.t.k9y")
          # @!attribute short_id [String] short id (e.g. "k9y", "qk0.3")
          # @!attribute directory [String] absolute task directory
          # @!attribute spec_path [String] absolute task spec path
          # @!attribute worktree_path [String, nil] absolute recorded worktree path
          # @!attribute worktree_branch [String, nil] recorded worktree branch
          Entry = Data.define(:full_id, :short_id, :directory, :spec_path, :worktree_path, :worktree_branch)

          # @param entries [Array<Entry>] indexed tasks (unique short ids)
          # @param available [Boolean] whether a `.ace-tasks/` tree was found
          # @param project_root [String] project root the index was built from
          def initialize(entries: [], available: false, project_root: nil)
            @entries = entries.freeze
            @available = available
            @project_root = project_root
            @canonical_directories = {}
            @canonical_worktree_paths = {}
          end

          attr_reader :entries, :project_root

          # Whether the project has a `.ace-tasks/` tree.
          # @return [Boolean]
          def available?
            @available
          end

          # @return [Boolean]
          def empty?
            @entries.empty?
          end

          # Find an entry by short or full id.
          #
          # @param reference [String, nil]
          # @return [Entry, nil]
          def entry_for_reference(reference)
            token = reference.to_s.strip
            return nil if token.empty?

            @entries.find { |entry| entry.full_id == token || entry.short_id == token }
          end

          # Whether the reference resolves to a known task.
          #
          # @param reference [String, nil]
          # @return [Boolean]
          def task?(reference)
            !entry_for_reference(reference).nil?
          end

          # Resolve an arbitrary string to a short task id when it names a known
          # task (extracting a task reference from it first).
          #
          # @param reference [String, nil]
          # @return [String, nil]
          def short_id_for(reference)
            entry = entry_for_reference(reference)
            return entry.short_id if entry

            extracted = Atoms::TaskIDExtractor.normalize(reference)
            extracted && task?(extracted) ? extracted : nil
          end

          # Find the task whose recorded worktree path matches.
          #
          # @param path [String, nil]
          # @return [Entry, nil]
          def find_by_worktree_path(path)
            return nil if path.to_s.empty?

            expanded = canonical_path(path)
            @entries.find do |entry|
              entry.worktree_path && canonical_worktree_path(entry) == expanded
            end
          end

          # Find the task whose recorded worktree branch matches.
          #
          # @param branch [String, nil]
          # @return [Entry, nil]
          def find_by_worktree_branch(branch)
            return nil if branch.to_s.empty?

            @entries.find { |entry| entry.worktree_branch == branch }
          end

          # Find the task owning an absolute task directory.
          #
          # @param directory [String, nil]
          # @return [Entry, nil]
          def find_by_directory(directory)
            return nil if directory.to_s.empty?

            expanded = canonical_path(directory)
            @entries.find { |entry| canonical_directory(entry) == expanded }
          end

          # Map changed file paths to task candidates.
          #
          # Paths are relative to the project root (as produced by git). Files
          # changed under a task directory count towards that task; for a
          # changed spec file the candidate id still comes from its directory.
          #
          # @param paths [Array<String>] repo-relative changed paths
          # @return [Array<Hash>] `[{entry:, count:}]` sorted by count desc then
          #   short id asc
          def candidates_for_paths(paths)
            counts = Hash.new(0)
            Array(paths).each do |relative_path|
              next if relative_path.to_s.empty?

              absolute = canonical_path(File.expand_path(relative_path, @project_root || Dir.pwd))
              entry = find_by_enclosing_directory(absolute)
              counts[entry] += 1 if entry
            end

            counts.map { |entry, count| {entry: entry, count: count} }
              .sort_by { |candidate| [-candidate[:count], candidate[:entry].short_id] }
          end

          private

          # Locate the indexed task directory containing a file path (any depth
          # under the task directory, including nested spec/artifact folders).
          def find_by_enclosing_directory(absolute_path)
            @entries.find do |entry|
              directory = canonical_directory(entry)
              absolute_path == directory || absolute_path.start_with?("#{directory}/")
            end
          end

          # Canonical forms are compared on every lookup; resolve each entry's
          # directory / recorded worktree path exactly once (realpath is a
          # syscall per path component and dominates lookup time otherwise).
          def canonical_directory(entry)
            @canonical_directories.fetch(entry) { @canonical_directories[entry] = canonical_path(entry.directory) }
          end

          def canonical_worktree_path(entry)
            @canonical_worktree_paths.fetch(entry) do
              @canonical_worktree_paths[entry] = entry.worktree_path ? canonical_path(entry.worktree_path) : nil
            end
          end

          # Canonical comparison form for paths that may be reached through a
          # symlinked root (e.g. macOS /var -> /private/var).
          def canonical_path(value)
            expanded = File.expand_path(value)
            return File.realpath(expanded) if File.exist?(expanded)

            parent = File.dirname(expanded)
            return expanded if parent == expanded

            File.join(canonical_path(parent), File.basename(expanded))
          rescue StandardError
            File.expand_path(value)
          end
        end
      end
    end
  end
end
