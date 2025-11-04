# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Task fetcher molecule
        #
        # Fetches task metadata from ace-taskflow CLI and parses the output.
        # Handles various task ID formats and provides error handling.
        #
        # @example Fetch task metadata
        #   fetcher = TaskFetcher.new
        #   task = fetcher.fetch("081")
        #   task.title # => "Fix authentication bug"
        #
        # @example Handle non-existent task
        #   task = fetcher.fetch("999")
        #   task # => nil
        class TaskFetcher
          # Default timeout for ace-taskflow commands
          DEFAULT_TIMEOUT = 10

          # Initialize a new TaskFetcher
          #
          # @param timeout [Integer] Command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
          end

          # Fetch task metadata by reference
          #
          # @param task_ref [String] Task reference (081, task.081, v.0.9.0+081)
          # @return [TaskMetadata, nil] Task metadata or nil if not found
          #
          # @example
          #   fetcher = TaskFetcher.new
          #   task = fetcher.fetch("081")
          #   task = fetcher.fetch("task.081")
          #   task = fetcher.fetch("v.0.9.0+081")
          def fetch(task_ref)
            return nil if task_ref.nil? || task_ref.empty?

            # Normalize task reference
            normalized_ref = normalize_task_reference(task_ref)
            return nil unless normalized_ref

            # Execute ace-taskflow command
            output = execute_ace_taskflow(normalized_ref)
            return nil unless output

            # Parse the output
            parse_task_output(output)
          end

          # Fetch multiple tasks by references
          #
          # @param task_refs [Array<String>] Array of task references
          # @return [Array<TaskMetadata>] Array of task metadata (nil values filtered out)
          #
          # @example
          #   fetcher = TaskFetcher.new
          #   tasks = fetcher.fetch_many(["081", "082", "083"])
          def fetch_many(task_refs)
            Array(task_refs).map { |ref| fetch(ref) }.compact
          end

          # Search for tasks by pattern
          #
          # @param pattern [String] Search pattern
          # @param limit [Integer] Maximum number of results
          # @return [Array<TaskMetadata>] Array of matching tasks
          #
          # @example
          #   fetcher = TaskFetcher.new
          #   tasks = fetcher.search("auth", limit: 5)
          def search(pattern, limit: 10)
            return [] if pattern.nil? || pattern.empty?

            # Execute search command
            output = execute_search(pattern, limit)
            return [] unless output

            # Parse search results
            parse_search_results(output)
          end

          # Check if ace-taskflow is available
          #
          # @return [Boolean] true if ace-taskflow command is available
          def ace_taskflow_available?
            result = execute_command("ace-taskflow", "--version", timeout: 5)
            result[:success]
          end

          # Get ace-taskflow version
          #
          # @return [String, nil] Version string or nil if not available
          def ace_taskflow_version
            return nil unless ace_taskflow_available?

            result = execute_command("ace-taskflow", "--version", timeout: 5)
            return nil unless result[:success]

            # Extract version from output
            match = result[:output].match(/ace-taskflow\s+([\d.]+)/)
            match ? match[1] : nil
          end

          private

          # Normalize task reference to a standard format
          #
          # @param task_ref [String] Input task reference
          # @return [String, nil] Normalized reference or nil if invalid
          def normalize_task_reference(task_ref)
            ref = task_ref.to_s.strip

            # Extract numeric ID from various formats
            # Format 1: Just number (081)
            # Format 2: task.number (task.081)
            # Format 3: version+task.number (v.0.9.0+task.081)

            match = ref.match(/(\d+)/)
            return nil unless match

            # Return just the numeric part for ace-taskflow
            match[1]
          end

          # Execute ace-taskflow command to fetch task
          #
          # @param task_ref [String] Normalized task reference
          # @return [String, nil] Command output or nil if failed
          def execute_ace_taskflow(task_ref)
            result = execute_command("ace-taskflow", "task", "show", task_ref, "--content", timeout: @timeout)
            result[:success] ? result[:output] : nil
          end

          # Execute ace-taskflow search command
          #
          # @param pattern [String] Search pattern
          # @param limit [Integer] Result limit
          # @return [String, nil] Command output or nil if failed
          def execute_search(pattern, limit)
            result = execute_command("ace-taskflow", "tasks", "--search", pattern, "--limit", limit.to_s, timeout: @timeout)
            result[:success] ? result[:output] : nil
          end

          # Parse task output from ace-taskflow
          #
          # @param output [String] Raw output from ace-taskflow
          # @return [TaskMetadata, nil] Parsed task metadata or nil
          def parse_task_output(output)
            Models::TaskMetadata.from_ace_taskflow_output(output)
          end

          # Parse search results from ace-taskflow
          #
          # @param output [String] Raw search output from ace-taskflow
          # @return [Array<TaskMetadata>] Array of task metadata
          def parse_search_results(output)
            tasks = []

            # Each line typically contains a task reference and title
            output.split("\n").each do |line|
              # Extract task ID from line
              task_id_match = line.match(/\b(\d+)\b/)
              next unless task_id_match

              # Fetch full task metadata
              task = fetch(task_id_match[1])
              tasks << task if task
            end

            tasks
          end

          # Execute a command safely
          #
          # @param command [String] Command to execute
          # @param args [Array<String>] Command arguments
          # @param timeout [Integer] Command timeout
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_command(command, *args, timeout: DEFAULT_TIMEOUT)
            require "open3"

            full_command = [command] + args
            stdout, stderr, status = Open3.capture3(*full_command, timeout: timeout)

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
              error: "Command timed out after #{timeout} seconds",
              exit_code: 124
            }
          rescue StandardError => e
            {
              success: false,
              output: "",
              error: "Command execution failed: #{e.message}",
              exit_code: 1
            }
          end
        end
      end
    end
  end
end