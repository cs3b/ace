# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Configuration model for worktree settings
        class WorktreeConfig
          attr_reader :root_path, :mise_trust_auto, :mise_trust_timeout,
                      :task_directory_format, :task_branch_format,
                      :slug_max_length, :slug_separator,
                      :auto_mark_in_progress, :auto_commit_task,
                      :commit_message_format, :add_worktree_metadata,
                      :duplicate_suffix_format, :cleanup_on_merge,
                      :cleanup_on_delete, :cleanup_on_task_done,
                      :default_output_format, :show_absolute_paths,
                      :git_timeout, :auto_fetch

          # Default configuration values
          DEFAULTS = {
            root_path: ".ace-wt",
            mise_trust_auto: true,
            mise_trust_timeout: 5,
            task_directory_format: "task.{id}",
            task_branch_format: "{id}-{slug}",
            slug_max_length: 50,
            slug_separator: "-",
            auto_mark_in_progress: true,
            auto_commit_task: true,
            commit_message_format: "chore(task-{id}): mark as in-progress, creating worktree",
            add_worktree_metadata: true,
            duplicate_suffix_format: "-{count}",
            cleanup_on_merge: false,
            cleanup_on_delete: true,
            cleanup_on_task_done: false,
            default_output_format: "table",
            show_absolute_paths: true,
            git_timeout: 30,
            auto_fetch: false
          }.freeze

          def initialize(config_hash = {})
            merged = DEFAULTS.merge(flatten_config(config_hash))

            @root_path = merged[:root_path]
            @mise_trust_auto = merged[:mise_trust_auto]
            @mise_trust_timeout = merged[:mise_trust_timeout]
            @task_directory_format = merged[:task_directory_format]
            @task_branch_format = merged[:task_branch_format]
            @slug_max_length = merged[:slug_max_length]
            @slug_separator = merged[:slug_separator]
            @auto_mark_in_progress = merged[:auto_mark_in_progress]
            @auto_commit_task = merged[:auto_commit_task]
            @commit_message_format = merged[:commit_message_format]
            @add_worktree_metadata = merged[:add_worktree_metadata]
            @duplicate_suffix_format = merged[:duplicate_suffix_format]
            @cleanup_on_merge = merged[:cleanup_on_merge]
            @cleanup_on_delete = merged[:cleanup_on_delete]
            @cleanup_on_task_done = merged[:cleanup_on_task_done]
            @default_output_format = merged[:default_output_format]
            @show_absolute_paths = merged[:show_absolute_paths]
            @git_timeout = merged[:git_timeout]
            @auto_fetch = merged[:auto_fetch]
          end

          # Check if configuration is valid
          def valid?
            errors.empty?
          end

          # Get validation errors
          def errors
            errs = []
            errs << "root_path cannot be empty" if root_path.nil? || root_path.empty?
            errs << "task_directory_format cannot be empty" if task_directory_format.nil? || task_directory_format.empty?
            errs << "task_branch_format cannot be empty" if task_branch_format.nil? || task_branch_format.empty?
            errs << "slug_max_length must be positive" if slug_max_length.to_i <= 0
            errs << "mise_trust_timeout must be positive" if mise_trust_timeout.to_i <= 0
            errs << "git_timeout must be positive" if git_timeout.to_i <= 0
            errs << "default_output_format must be 'table' or 'json'" unless %w[table json].include?(default_output_format)
            errs
          end

          # Convert to hash representation
          def to_h
            {
              root_path: root_path,
              mise_trust_auto: mise_trust_auto,
              mise_trust_timeout: mise_trust_timeout,
              task: {
                directory_format: task_directory_format,
                branch_format: task_branch_format,
                slug_max_length: slug_max_length,
                slug_separator: slug_separator,
                auto_mark_in_progress: auto_mark_in_progress,
                auto_commit_task: auto_commit_task,
                commit_message_format: commit_message_format,
                add_worktree_metadata: add_worktree_metadata,
                duplicate_suffix_format: duplicate_suffix_format
              },
              cleanup: {
                on_merge: cleanup_on_merge,
                on_delete: cleanup_on_delete,
                on_task_done: cleanup_on_task_done
              },
              output: {
                default_format: default_output_format,
                show_absolute_paths: show_absolute_paths
              },
              git: {
                worktree_command_timeout: git_timeout,
                auto_fetch: auto_fetch
              }
            }
          end

          private

          # Flatten nested configuration hash
          def flatten_config(hash)
            result = {}

            # Handle root level
            result[:root_path] = hash[:root_path] if hash[:root_path]
            result[:mise_trust_auto] = hash[:mise_trust_auto] if hash.key?(:mise_trust_auto)
            result[:mise_trust_timeout] = hash[:mise_trust_timeout] if hash[:mise_trust_timeout]

            # Handle task section
            if hash[:task]
              task = hash[:task]
              result[:task_directory_format] = task[:directory_format] if task[:directory_format]
              result[:task_branch_format] = task[:branch_format] if task[:branch_format]
              result[:slug_max_length] = task[:slug_max_length] if task[:slug_max_length]
              result[:slug_separator] = task[:slug_separator] if task[:slug_separator]
              result[:auto_mark_in_progress] = task[:auto_mark_in_progress] if task.key?(:auto_mark_in_progress)
              result[:auto_commit_task] = task[:auto_commit_task] if task.key?(:auto_commit_task)
              result[:commit_message_format] = task[:commit_message_format] if task[:commit_message_format]
              result[:add_worktree_metadata] = task[:add_worktree_metadata] if task.key?(:add_worktree_metadata)
              result[:duplicate_suffix_format] = task[:duplicate_suffix_format] if task[:duplicate_suffix_format]
            end

            # Handle cleanup section
            if hash[:cleanup]
              cleanup = hash[:cleanup]
              result[:cleanup_on_merge] = cleanup[:on_merge] if cleanup.key?(:on_merge)
              result[:cleanup_on_delete] = cleanup[:on_delete] if cleanup.key?(:on_delete)
              result[:cleanup_on_task_done] = cleanup[:on_task_done] if cleanup.key?(:on_task_done)
            end

            # Handle output section
            if hash[:output]
              output = hash[:output]
              result[:default_output_format] = output[:default_format] if output[:default_format]
              result[:show_absolute_paths] = output[:show_absolute_paths] if output.key?(:show_absolute_paths)
            end

            # Handle git section
            if hash[:git]
              git = hash[:git]
              result[:git_timeout] = git[:worktree_command_timeout] if git[:worktree_command_timeout]
              result[:auto_fetch] = git[:auto_fetch] if git.key?(:auto_fetch)
            end

            result
          end
        end
      end
    end
  end
end