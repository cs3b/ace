# frozen_string_literal: true

# Try to require ace-task API for direct integration (organism level only)
begin
  require "ace/task/organisms/task_manager"
rescue LoadError
  # ace-task not available - will fall back to CLI
end

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Molecules
        # Task status updater molecule
        #
        # Updates task status using ace-task Ruby API or CLI commands.
        # Provides methods for marking tasks as in-progress, done, etc.
        # All methods return a result hash with :success and :message keys.
        #
        # @example Mark task as in-progress
        #   updater = TaskStatusUpdater.new
        #   result = updater.mark_in_progress("8pp.t.q7w")
        #   # => { success: true, message: "Task status updated to in-progress" }
        #
        # @example Update with custom status
        #   result = updater.update_status("8pp.t.q7w", "done")
        class TaskStatusUpdater
          # Default timeout for ace-task commands
          DEFAULT_TIMEOUT = 10

          # Initialize a new TaskStatusUpdater
          #
          # @param timeout [Integer] Command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
            @project_root = ENV["PROJECT_ROOT_PATH"] || Dir.pwd
          end

          # Mark task as in-progress
          #
          # @param task_ref [String] Task reference
          # @return [Hash] Result with :success and :message keys
          def mark_in_progress(task_ref)
            update_status(task_ref, "in-progress")
          end

          # Mark task as done
          #
          # @param task_ref [String] Task reference
          # @return [Hash] Result with :success and :message keys
          def mark_done(task_ref)
            update_status(task_ref, "done")
          end

          # Mark task as blocked
          #
          # @param task_ref [String] Task reference
          # @return [Hash] Result with :success and :message keys
          def mark_blocked(task_ref)
            update_status(task_ref, "blocked")
          end

          # Update task to custom status
          #
          # @param task_ref [String] Task reference
          # @param status [String] New status value
          # @return [Hash] Result with :success and :message keys
          def update_status(task_ref, status)
            return {success: false, message: "Task reference is required"} if task_ref.nil? || task_ref.empty?
            return {success: false, message: "Status is required"} if status.nil? || status.empty?

            puts "DEBUG: TaskStatusUpdater.update_status called with task_ref=#{task_ref}, status=#{status}" if ENV["DEBUG"]
            puts "DEBUG: use_ruby_api? = #{use_ruby_api?}" if ENV["DEBUG"]

            # Try Ruby API first (preferred in mono-repo)
            if use_ruby_api?
              puts "DEBUG: Using Ruby API for status update" if ENV["DEBUG"]
              result = update_status_via_api(task_ref, status)
              puts "DEBUG: Ruby API result: #{result}" if ENV["DEBUG"]
              return result
            end

            # Fallback to CLI for standalone installations
            puts "DEBUG: Using CLI for status update" if ENV["DEBUG"]
            result = update_status_via_cli(task_ref, status)
            puts "DEBUG: CLI result: #{result}" if ENV["DEBUG"]
            result
          end

          # Update task priority
          #
          # @param task_ref [String] Task reference
          # @param priority [String] New priority (high, medium, low)
          # @return [Boolean] true if priority was updated successfully
          def update_priority(task_ref, priority)
            return false unless %w[high medium low].include?(priority.to_s)

            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            if use_ruby_api?
              return update_fields_via_api(normalized_ref, {"priority" => priority})
            end

            result = execute_ace_task_command("update", normalized_ref, "--set", "priority=#{priority}")
            result[:success]
          end

          # Update task estimate
          #
          # @param task_ref [String] Task reference
          # @param estimate [String] New estimate (e.g., "2h", "1-2 days")
          # @return [Boolean] true if estimate was updated successfully
          def update_estimate(task_ref, estimate)
            return false if estimate.nil? || estimate.empty?

            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            if use_ruby_api?
              return update_fields_via_api(normalized_ref, {"estimate" => estimate})
            end

            result = execute_ace_task_command("update", normalized_ref, "--set", "estimate=#{estimate}")
            result[:success]
          end

          # Add worktree metadata to task
          #
          # @param task_ref [String] Task reference
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata to add
          # @return [Boolean] true if metadata was added successfully
          def add_worktree_metadata(task_ref, worktree_metadata)
            return false unless worktree_metadata.is_a?(Models::WorktreeMetadata)

            # Try Ruby API first (preferred in mono-repo)
            if use_ruby_api?
              return add_worktree_metadata_via_api(task_ref, worktree_metadata)
            end

            # Fallback to CLI for standalone installations
            add_worktree_metadata_via_cli(task_ref, worktree_metadata)
          end

          # Add PR metadata to task
          #
          # @param task_ref [String] Task reference
          # @param pr_data [Hash] PR data with :number, :url, :created_at
          # @return [Boolean] true if metadata was added successfully
          def add_pr_metadata(task_ref, pr_data)
            return false unless pr_data.is_a?(Hash)
            return false unless pr_data[:number] && pr_data[:url]

            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            # Try Ruby API first (preferred in mono-repo)
            if use_ruby_api?
              return add_pr_metadata_via_api(task_ref, pr_data)
            end

            # Fallback to CLI for standalone installations
            add_pr_metadata_via_cli(task_ref, pr_data)
          end

          # Add started_at timestamp to task
          #
          # @param task_ref [String] Task reference
          # @return [Boolean] true if timestamp was added successfully
          def add_started_at_timestamp(task_ref)
            started_at = Time.now

            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            # Try Ruby API first (preferred in mono-repo)
            if use_ruby_api?
              return add_started_at_via_api(task_ref, started_at)
            end

            # Fallback to CLI for standalone installations
            add_started_at_via_cli(task_ref, started_at)
          end

          # Remove worktree metadata from task
          #
          # @param task_ref [String] Task reference
          # @return [Boolean] true if metadata was removed successfully
          def remove_worktree_metadata(task_ref)
            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            false
          end

          # Get current task status
          #
          # @param task_ref [String] Task reference
          # @return [String, nil] Current status or nil if not found
          def get_status(task_ref)
            normalized_ref = normalize_task_reference(task_ref)
            return nil unless normalized_ref

            # Fetch task metadata
            fetcher = TaskFetcher.new
            task = fetcher.fetch(normalized_ref)
            task ? task[:status] : nil
          end

          # Check if ace-task update command is available
          #
          # @return [Boolean] true if update command is available
          def update_command_available?
            result = execute_ace_task_command("update", "--help", timeout: 5)
            result[:success]
          end

          private

          # Check if we can use Ruby API
          #
          # @return [Boolean] true if Ruby API is available
          def use_ruby_api?
            defined?(Ace::Task::Organisms::TaskManager)
          end

          # Update task status using Ruby API
          #
          # @param task_ref [String] Task reference
          # @param status [String] New status
          # @return [Hash] Result with :success and :message keys
          def update_status_via_api(task_ref, status)
            task_manager = Ace::Task::Organisms::TaskManager.new
            result = task_manager.update(task_ref, set: {"status" => status})

            puts "DEBUG: TaskManager result: #{result.inspect}" if ENV["DEBUG"]

            if result
              {success: true, message: "Task status updated to #{status}"}
            else
              puts "DEBUG: TaskManager returned nil" if ENV["DEBUG"]
              {success: false, message: "Failed to update task status"}
            end
          rescue => e
            puts "DEBUG: TaskManager exception: #{e.message}" if ENV["DEBUG"]
            # Fall back to CLI on API error
            update_status_via_cli(task_ref, status)
          end

          # Update task status using CLI
          #
          # @param task_ref [String] Task reference
          # @param status [String] New status
          # @return [Hash] Result with :success and :message keys
          def update_status_via_cli(task_ref, status)
            normalized_ref = normalize_task_reference(task_ref)
            return {success: false, message: "Invalid task reference"} unless normalized_ref

            result = execute_ace_task_command("update", normalized_ref, "--set", "status=#{status}")
            if result[:success]
              {success: true, message: "Task status updated to #{status}"}
            else
              {success: false, message: result[:error] || "Failed to update task status"}
            end
          end

          # Update fields using Ruby API
          #
          # @param task_ref [String] Task reference
          # @param fields [Hash] Fields to update
          # @return [Boolean] true if successful
          def update_fields_via_api(task_ref, fields)
            task_manager = Ace::Task::Organisms::TaskManager.new
            result = task_manager.update(task_ref, set: fields)
            !result.nil?
          rescue
            false
          end

          # Add worktree metadata using Ruby API
          #
          # @param task_ref [String] Task reference
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Boolean] true if successful
          def add_worktree_metadata_via_api(task_ref, worktree_metadata)
            task_manager = Ace::Task::Organisms::TaskManager.new

            # Convert worktree metadata to field updates
            metadata_hash = worktree_metadata.to_h
            field_updates = {}
            metadata_hash.each do |field, value|
              field_updates["worktree.#{field}"] = value.to_s
            end

            result = task_manager.update(task_ref, set: field_updates)
            !result.nil?
          rescue
            # Fall back to CLI on API error
            add_worktree_metadata_via_cli(task_ref, worktree_metadata)
          end

          # Add worktree metadata using CLI
          #
          # @param task_ref [String] Task reference
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Boolean] true if successful
          def add_worktree_metadata_via_cli(task_ref, worktree_metadata)
            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            metadata_hash = worktree_metadata.to_h
            success = true

            metadata_hash.each do |field, value|
              field_path = "worktree.#{field}"
              result = execute_ace_task_command("update", normalized_ref, "--set", "#{field_path}=#{value}")
              success &&= result[:success]
            end

            success
          end

          # Add PR metadata using Ruby API
          #
          # @param task_ref [String] Task reference
          # @param pr_data [Hash] PR data
          # @return [Boolean] true if successful
          def add_pr_metadata_via_api(task_ref, pr_data)
            task_manager = Ace::Task::Organisms::TaskManager.new

            field_updates = {
              "pr.number" => pr_data[:number].to_s,
              "pr.url" => pr_data[:url].to_s
            }
            field_updates["pr.created_at"] = pr_data[:created_at].iso8601 if pr_data[:created_at]

            result = task_manager.update(task_ref, set: field_updates)
            !result.nil?
          rescue
            # Fall back to CLI on API error
            add_pr_metadata_via_cli(task_ref, pr_data)
          end

          # Add PR metadata using CLI
          #
          # @param task_ref [String] Task reference
          # @param pr_data [Hash] PR data
          # @return [Boolean] true if successful
          def add_pr_metadata_via_cli(task_ref, pr_data)
            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            success = true

            result = execute_ace_task_command("update", normalized_ref, "--set", "pr.number=#{pr_data[:number]}")
            success &&= result[:success]

            result = execute_ace_task_command("update", normalized_ref, "--set", "pr.url=#{pr_data[:url]}")
            success &&= result[:success]

            if pr_data[:created_at]
              timestamp = pr_data[:created_at].respond_to?(:iso8601) ? pr_data[:created_at].iso8601 : pr_data[:created_at].to_s
              result = execute_ace_task_command("update", normalized_ref, "--set", "pr.created_at=#{timestamp}")
              success &&= result[:success]
            end

            success
          end

          # Add started_at timestamp using Ruby API
          #
          # @param task_ref [String] Task reference
          # @param started_at [Time] Start timestamp
          # @return [Boolean] true if successful
          def add_started_at_via_api(task_ref, started_at)
            task_manager = Ace::Task::Organisms::TaskManager.new

            field_updates = {"started_at" => started_at.iso8601}

            result = task_manager.update(task_ref, set: field_updates)
            !result.nil?
          rescue
            # Fall back to CLI on API error
            add_started_at_via_cli(task_ref, started_at)
          end

          # Add started_at timestamp using CLI
          #
          # @param task_ref [String] Task reference
          # @param started_at [Time] Start timestamp
          # @return [Boolean] true if successful
          def add_started_at_via_cli(task_ref, started_at)
            normalized_ref = normalize_task_reference(task_ref)
            return false unless normalized_ref

            timestamp = started_at.respond_to?(:iso8601) ? started_at.iso8601 : started_at.to_s
            result = execute_ace_task_command("update", normalized_ref, "--set", "started_at=#{timestamp}")
            result[:success]
          end

          # Normalize task reference to a standard format
          #
          # @param task_ref [String] Input task reference
          # @return [String, nil] Normalized reference or nil if invalid
          def normalize_task_reference(task_ref)
            Atoms::TaskIDExtractor.normalize(task_ref)
          end

          # Execute ace-task command
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_ace_task_command(*args)
            require "open3"

            full_command = ["ace-task"] + args

            stdout, stderr, status = Open3.capture3(*full_command, timeout: @timeout)

            {
              success: status.success?,
              output: stdout.to_s,
              error: stderr.to_s,
              exit_code: status.exitstatus
            }
          rescue Open3::CommandTimeout
            {
              success: false,
              output: "",
              error: "ace-task command timed out after #{@timeout} seconds",
              exit_code: 124
            }
          rescue => e
            {
              success: false,
              output: "",
              error: "ace-task command failed: #{e.message}",
              exit_code: 1
            }
          end
        end
      end
    end
  end
end
