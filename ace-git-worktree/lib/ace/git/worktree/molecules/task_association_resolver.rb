# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"
require_relative "../models/task_index"

module Ace
  module Git
    module Worktree
      module Molecules
        # Resolves a worktree to a task id without depending on worktree names.
        #
        # Precedence (first hit wins):
        # 1. recorded task frontmatter metadata (`worktree.path` / `worktree.branch`);
        # 2. the `_current` symlink at the worktree root resolving under `.ace-tasks/`;
        # 3. a validated path/branch name extraction (rejected when the extracted
        #    id names no known task);
        # 4. task files changed inside the worktree (uncommitted first, then
        #    committed against the primary branch merge-base);
        # 5. unresolved (`task_id` stays nil -> rendered `-`).
        class TaskAssociationResolver
          # Task-provenance values exposed in JSON `task_id_source`.
          SOURCES = %w[metadata symlink path branch task_files].freeze

          # @param task_index [Models::TaskIndex]
          def initialize(task_index:)
            @task_index = task_index || Models::TaskIndex.new
          end

          # @param worktree [Models::WorktreeInfo]
          # @param probe [Hash, nil] probe payload for this worktree
          # @return [Models::WorktreeInfo] copy carrying task resolution fields
          def resolve(worktree, probe)
            resolved = resolve_source(worktree, probe || {})
            worktree.with_enrichment(
              task_id: resolved[:task_id],
              task_id_source: resolved[:source],
              task_ids: resolved[:task_ids]
            )
          end

          private

          def resolve_source(worktree, probe)
            if (entry = recorded_metadata_entry(worktree))
              return resolved_entry(entry, "metadata")
            end

            if (entry = symlink_entry(probe))
              return resolved_entry(entry, "symlink")
            end

            if (named = name_extraction(worktree))
              return named
            end

            if (inferred = task_file_inference(probe))
              return inferred
            end

            {task_id: nil, source: nil, task_ids: []}
          end

          def resolved_entry(entry, source)
            {task_id: entry.short_id, source: source, task_ids: [entry.short_id]}
          end

          def recorded_metadata_entry(worktree)
            @task_index.find_by_worktree_path(worktree.path) ||
              @task_index.find_by_worktree_branch(worktree.branch)
          end

          def symlink_entry(probe)
            target = probe[:symlink_target]
            return nil if target.to_s.empty?

            @task_index.find_by_directory(target)
          end

          # Validate the existing path -> branch name extraction. Without a
          # `.ace-tasks/` tree the extraction is accepted as before; with a task
          # tree, the extracted id must resolve to a known task so meaningless
          # directory names (e.g. "ace") do not pollute the Task column.
          def name_extraction(worktree)
            from_path = Atoms::TaskIDExtractor.normalize(File.basename(worktree.path))
            if from_path && acceptable?(from_path)
              return {task_id: from_path, source: "path", task_ids: [from_path]}
            end

            from_branch = worktree.branch && Atoms::TaskIDExtractor.normalize(worktree.branch)
            if from_branch && acceptable?(from_branch)
              return {task_id: from_branch, source: "branch", task_ids: [from_branch]}
            end

            nil
          end

          def acceptable?(task_id)
            return true unless @task_index.available?

            @task_index.task?(task_id)
          end

          def task_file_inference(probe)
            paths = Array(probe[:changed_task_files])
            paths = Array(probe[:committed_task_files]) if paths.empty?
            return nil if paths.empty?

            candidates = @task_index.candidates_for_paths(paths)
            return nil if candidates.empty?

            {
              task_id: candidates.first[:entry].short_id,
              source: "task_files",
              task_ids: candidates.map { |candidate| candidate[:entry].short_id }
            }
          end
        end
      end
    end
  end
end
