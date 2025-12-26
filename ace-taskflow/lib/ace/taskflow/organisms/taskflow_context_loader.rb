# frozen_string_literal: true

require_relative "../molecules/task_loader"
require_relative "../molecules/release_resolver"
require_relative "../molecules/task_activity_analyzer"
require_relative "../molecules/codename_extractor"
require_relative "../atoms/task_reference_parser"
require_relative "task_manager"
require "ace/git"

module Ace
  module Taskflow
    module Organisms
      # Orchestrates loading taskflow context
      # Focuses on taskflow-specific information (release, task)
      # Git state is available via ace-git context command
      class TaskflowContextLoader
        # Load taskflow context
        # @since 0.24.0
        # @param options [Hash] Options
        # @option options [Boolean] :include_activity Include task activity (default: true)
        # @return [Hash] Taskflow context with task and release info
        def self.load(options = {})
          new.load(options)
        end

        # Initialize the loader
        # @param root_path [String, nil] Root path for taskflow (defaults to configured root)
        # @note The @primary_release cache persists for the loader instance lifetime.
        #   Each load() call reuses the cached release. If you need fresh release data,
        #   create a new loader instance. This is the expected behavior for single
        #   context loads, but be aware if reusing loader instances across operations.
        def initialize(root_path: nil)
          @root_path = root_path || default_root_path
          @primary_release = nil # Cache for release to avoid duplicate lookups
        end

        # Load taskflow context (task and release information)
        # @since 0.24.0
        # @param options [Hash] Options
        # @option options [Boolean] :include_activity Include task activity (default: true)
        # @option options [Integer] :recently_done_limit Override config for recently done limit
        # @option options [Integer] :up_next_limit Override config for up next limit
        # @option options [Boolean] :include_drafts Override config for including drafts
        # @return [Hash] Taskflow context with task and release info
        def load(options = {})
          include_activity = options.fetch(:include_activity, true)

          # Detect task pattern from current branch name
          task_pattern = detect_task_pattern_from_branch

          # Resolve task from pattern if found
          resolved_task = resolve_task(task_pattern) if task_pattern

          # Get current release info (caches @primary_release for reuse)
          release_info = load_release_info

          result = {
            task: resolved_task,
            release: release_info
          }

          # Load task activity if requested (reuses cached @primary_release)
          # Pass through activity options for CLI override support (ADR-022)
          if include_activity
            activity_options = options.slice(
              :recently_done_limit,
              :up_next_limit,
              :include_drafts
            )
            result[:task_activity] = load_task_activity(resolved_task, activity_options)
          end

          result
        end

        private

        def resolve_task(task_pattern)
          return nil unless task_pattern

          loader = Molecules::TaskLoader.new(@root_path)
          task = loader.find_task_by_reference(task_pattern)

          return nil unless task

          {
            id: task[:id],
            title: task[:title],
            status: task[:status],
            path: task[:path],
            priority: task[:priority],
            estimate: task[:estimate],
            is_orchestrator: task[:is_orchestrator],
            subtask_ids: task[:subtask_ids],
            # Extract parent task number from parent_id for context display
            # parent_id is canonical (e.g., "v.0.9.0+task.140"), parent is extracted number (e.g., "140")
            parent: task[:parent_id] ? extract_parent_number(task[:parent_id]) : nil
          }
        end

        def load_release_info
          # Cache the primary release for reuse in load_task_activity
          @primary_release ||= begin
            resolver = Molecules::ReleaseResolver.new(@root_path)
            resolver.find_primary_active
          end

          return nil unless @primary_release

          # IMPORTANT: Use TaskManager.get_statistics() for consistent counts with `ace-taskflow tasks`
          # ReleaseResolver uses simple glob patterns that miss hierarchical tasks.
          # TaskManager uses the correct hierarchical patterns (tasks/**/task.[0-9]*.s.md etc.)
          # See: https://github.com/cs3b/ace-meta/pull/83 - this was causing status to show 0/31
          # while tasks showed 15/136 (3rd regression of this bug)
          task_manager = TaskManager.new
          stats = task_manager.get_statistics(release: @primary_release[:name])

          total = stats[:total]
          by_status = stats[:by_status]
          done = (by_status["done"] || 0) + (by_status["completed"] || 0)
          progress = total > 0 ? ((done.to_f / total) * 100).round : 0

          # Extract codename from release directory (e.g., "Mono-Repo Multiple Gems")
          codename = extract_codename_from_path(@primary_release[:path])

          {
            name: @primary_release[:name],
            version: @primary_release[:version],
            path: @primary_release[:path],
            status: @primary_release[:status],
            total_tasks: total,
            done_tasks: done,
            progress: progress,
            codename: codename,
            stats: by_status
          }
        end

        def default_root_path
          # Use configuration to find taskflow root
          Ace::Taskflow.configuration.root_directory
        end

        # Detect task pattern from current git branch name
        # Extracts task number from branch names like "140.02-update-feature" or "140-feature"
        # @return [String, nil] Task pattern (e.g., "140.02", "140") or nil if not found
        def detect_task_pattern_from_branch
          # Use BranchReader from ace-git for consistent error handling and testability
          branch = Ace::Git::Molecules::BranchReader.current_branch
          return nil if branch.nil? || branch == "HEAD"

          # Extract task pattern: matches "140.02" or "140" at start of branch name
          # Pattern: starts with digits, optionally followed by .digits, before first hyphen
          branch[/^(\d+(?:\.\d+)?)-/, 1]
        end

        # Extract task number from parent_id (e.g., "v.0.9.0+task.140" -> "140")
        # Returns nil if parent_id is nil or format is invalid
        # Delegates to TaskReferenceParser for consistent parsing
        def extract_parent_number(parent_id)
          return nil unless parent_id
          Atoms::TaskReferenceParser.extract_number(parent_id)
        end

        # Extract codename from release directory's main markdown file
        # Delegates to CodenameExtractor molecule for better testability
        # @param release_path [String] Path to release directory
        # @return [String, nil] Codename or nil if not found
        def extract_codename_from_path(release_path)
          Molecules::CodenameExtractor.extract(release_path)
        end

        # Load task activity (recently done, in progress, up next)
        # Uses cached @primary_release to avoid duplicate ReleaseResolver calls
        # Configuration is loaded from Ace::Taskflow.configuration (ADR-022)
        # @param current_task [Hash, nil] Current task to exclude from in_progress
        # @param options [Hash] Override options (from CLI flags)
        # @return [Hash] Activity data with :recently_done, :in_progress, :up_next
        def load_task_activity(current_task, options = {})
          loader = Molecules::TaskLoader.new(@root_path)

          # Load tasks from current release only (performance optimization)
          # Uses load_tasks_from_release instead of load_all_tasks to avoid
          # loading historical releases as the project grows
          all_tasks = if @primary_release
                        loader.load_tasks_from_release(@primary_release[:path])
                      else
                        loader.load_all_tasks
                      end

          current_task_id = current_task ? current_task[:id] : nil

          # Get configuration values (ADR-022: config > hardcoded defaults)
          config = Ace::Taskflow.configuration

          # Use options.key? pattern to allow explicit 0/false values from CLI to override config
          # The || pattern would ignore 0/false, collapsing back to config defaults
          Molecules::TaskActivityAnalyzer.categorize_activities(
            all_tasks,
            current_task_id: current_task_id,
            recently_done_limit: options.key?(:recently_done_limit) ? options[:recently_done_limit] : config.recently_done_limit,
            up_next_limit: options.key?(:up_next_limit) ? options[:up_next_limit] : config.up_next_limit,
            include_drafts: options.key?(:include_drafts) ? options[:include_drafts] : config.include_drafts_in_up_next?
          )
        end
      end
    end
  end
end
