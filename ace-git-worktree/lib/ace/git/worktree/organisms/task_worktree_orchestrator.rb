# frozen_string_literal: true

require_relative "../molecules/task_fetcher"
require_relative "../molecules/task_status_updater"
require_relative "../molecules/task_committer"
require_relative "../molecules/worktree_creator"
require_relative "../molecules/mise_trustor"
require_relative "../models/worktree_metadata"
require_relative "../atoms/slug_generator"

module Ace
  module Git
    module Worktree
      module Organisms
        # Orchestrates the complete task-aware worktree creation workflow
        class TaskWorktreeOrchestrator
          attr_reader :config

          def initialize(config = nil)
            @config = config || Worktree.configuration
          end

          # Create a worktree for a task
          # @param task_reference [String] Task ID or reference
          # @param options [Hash] Options for creation
          # @return [Hash] Result with details of created worktree
          def create_task_worktree(task_reference, options = {})
            # Step 1: Fetch task metadata
            task = fetch_task(task_reference)
            return task unless task[:success]

            task_metadata = task[:metadata]

            # Step 2: Generate worktree path and branch name
            naming = generate_naming(task_metadata, options)

            # Step 3: Update task status to in-progress (if configured)
            if should_update_status?(options)
              status_result = update_task_status(task_metadata)
              unless status_result[:success]
                return status_result unless options[:continue_on_error]
              end
            end

            # Step 4: Add worktree metadata to task (if configured)
            if should_add_metadata?(options)
              metadata_result = add_worktree_metadata(task_metadata, naming)
              unless metadata_result[:success]
                return metadata_result unless options[:continue_on_error]
              end
            end

            # Step 5: Commit task changes (if configured)
            if should_commit?(options)
              commit_result = commit_task_changes(task_metadata, options)
              unless commit_result[:success]
                return commit_result unless options[:continue_on_error]
              end
            end

            # Step 6: Create the worktree
            worktree_result = create_worktree(naming[:path], naming[:branch], options)
            return worktree_result unless worktree_result[:success]

            # Step 7: Trust mise.toml (if configured)
            if should_trust_mise?(options)
              mise_result = trust_mise(worktree_result[:path])
              # Mise trust failures are non-fatal
              if mise_result[:warning]
                worktree_result[:warnings] ||= []
                worktree_result[:warnings] << mise_result[:output]
              end
            end

            # Return success with all details
            {
              success: true,
              path: worktree_result[:path],
              branch: naming[:branch],
              task: {
                id: task_metadata.full_id,
                title: task_metadata.title,
                status: task_metadata.in_progress? ? "in-progress" : task_metadata.status
              },
              outputs: {
                absolute_path: File.expand_path(worktree_result[:path]),
                relative_path: naming[:path]
              }
            }.merge(worktree_result.slice(:warnings))
          end

          # Dry run - show what would be created
          # @param task_reference [String] Task ID
          # @param options [Hash] Options
          # @return [Hash] Preview of what would be created
          def dry_run(task_reference, options = {})
            # Fetch task metadata
            task = fetch_task(task_reference)
            return task unless task[:success]

            task_metadata = task[:metadata]

            # Generate naming
            naming = generate_naming(task_metadata, options)

            {
              success: true,
              dry_run: true,
              would_create: {
                directory: naming[:path],
                branch: naming[:branch],
                task: {
                  id: task_metadata.full_id,
                  title: task_metadata.title,
                  would_mark_in_progress: should_update_status?(options),
                  would_add_metadata: should_add_metadata?(options),
                  would_commit: should_commit?(options)
                },
                mise_trust: should_trust_mise?(options)
              }
            }
          end

          private

          def fetch_task(reference)
            metadata = Molecules::TaskFetcher.fetch(reference)
            if metadata
              { success: true, metadata: metadata }
            else
              {
                success: false,
                error: "Task not found: #{reference}. Use 'ace-taskflow tasks' to list available tasks."
              }
            end
          end

          def generate_naming(task_metadata, options = {})
            # Generate path from template
            path_template = options[:path] || @config.task_directory_format
            path = Atoms::SlugGenerator.format_template(path_template, task_metadata.template_variables)
            path = File.join(@config.root_path, path) unless path.start_with?("/")

            # Generate branch from template
            branch_template = @config.task_branch_format
            branch = Atoms::SlugGenerator.format_template(branch_template, task_metadata.template_variables)

            # Handle duplicate worktrees
            if Molecules::WorktreeLister.exists?(path)
              suffix_template = @config.duplicate_suffix_format || "-{count}"
              count = 2
              loop do
                suffix = suffix_template.gsub("{count}", count.to_s)
                new_path = "#{path}#{suffix}"
                new_branch = "#{branch}#{suffix}"
                unless Molecules::WorktreeLister.exists?(new_path)
                  path = new_path
                  branch = new_branch
                  break
                end
                count += 1
                break if count > 10 # Safeguard
              end
            end

            {
              path: path,
              branch: branch
            }
          end

          def update_task_status(task_metadata)
            return { success: true, skipped: true } if task_metadata.in_progress?

            Molecules::TaskStatusUpdater.mark_in_progress(task_metadata.id)
          end

          def add_worktree_metadata(task_metadata, naming)
            metadata = Models::WorktreeMetadata.new(
              branch: naming[:branch],
              path: naming[:path]
            )

            Molecules::TaskStatusUpdater.add_worktree_metadata(task_metadata.id, metadata)
          end

          def commit_task_changes(task_metadata, options)
            # Check if there are changes to commit
            unless Molecules::TaskCommitter.has_staged_changes?
              # Stage the task file if we updated it
              if task_metadata.path
                Molecules::TaskCommitter.stage_file(task_metadata.path)
              end
            end

            # Commit with configured or custom message
            message = options[:commit_message]
            Molecules::TaskCommitter.commit_task_changes(task_metadata, message, config: @config)
          end

          def create_worktree(path, branch, options)
            Molecules::WorktreeCreator.create(
              path: path,
              branch: branch,
              create_branch: true,
              timeout: @config.git_timeout
            )
          end

          def trust_mise(worktree_path)
            Molecules::MiseTrustor.trust(
              worktree_path,
              timeout: @config.mise_trust_timeout
            )
          end

          def should_update_status?(options)
            return false if options[:no_status_update]
            @config.auto_mark_in_progress
          end

          def should_add_metadata?(options)
            return false if options[:no_metadata]
            @config.add_worktree_metadata
          end

          def should_commit?(options)
            return false if options[:no_commit]
            @config.auto_commit_task
          end

          def should_trust_mise?(options)
            return false if options[:no_mise_trust]
            @config.mise_trust_auto
          end
        end
      end
    end
  end
end