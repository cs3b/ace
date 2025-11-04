# frozen_string_literal: true

# Try to require ace-taskflow API for direct integration
begin
  require "ace/taskflow/molecules/task_loader"
  require "ace/taskflow/atoms/task_reference_parser"
rescue LoadError
  # ace-taskflow not available - will fall back to CLI
end

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

          # Valid task ID pattern (3+ digits, optional prefix, more flexible)
          # Matches: 081, task.081, v.0.9.0+081, and supports the patterns used by WorktreeInfo
          TASK_ID_PATTERN = /\A(v\.\d+\.\d+\+)?(task[.-])?(\d{3,})\z/

          # Maximum task ID length
          MAX_TASK_ID_LENGTH = 50

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

            # Validate task reference for security early
            begin
              validate_task_reference(task_ref)
            rescue ArgumentError
              return nil
            end

            # Try direct API integration first (more reliable for completed tasks)
            if use_direct_api?
              task_data = fetch_via_direct_api(task_ref)
              return task_data ? create_task_metadata_from_data(task_data, task_ref) : nil
            end

            # Fallback to CLI-based approach
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

          # Get helpful error message when ace-taskflow is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def ace_taskflow_unavailable_message
            <<~MESSAGE
              ace-taskflow is not available or not in PATH.

              Required for task-aware worktree operations.

              Installation options:
              1. Install ace-taskflow gem: gem install ace-taskflow
              2. Add to your Gemfile: gem 'ace-taskflow'
              3. Ensure it's in your PATH: which ace-taskflow

              For more information: https://github.com/cs3b/ace-meta
            MESSAGE
          end

          # Check availability and return helpful error if unavailable
          #
          # @return [Hash] { available: boolean, message: string }
          def check_availability_with_message
            if ace_taskflow_available?
              { available: true, message: "ace-taskflow is available" }
            else
              { available: false, message: ace_taskflow_unavailable_message }
            end
          end

          # Check if ace-taskflow is available with caching
          #
          # @return [Boolean] true if ace-taskflow command is available
          def ace_taskflow_available_with_cache
            return @ace_taskflow_available if defined?(@ace_taskflow_available)

            result = execute_command("ace-taskflow", "--version", timeout: 5)
            @ace_taskflow_available = result[:success]
          end

          private

          # Check if we can use direct ace-taskflow API
          #
          # @return [Boolean] true if direct API is available
          def use_direct_api?
            defined?(Ace::Taskflow::Molecules::TaskLoader) && defined?(Ace::Taskflow::Atoms::TaskReferenceParser)
          end

          # Fetch task using direct ace-taskflow API
          #
          # @param task_ref [String] Task reference
          # @return [Hash, nil] Task data hash or nil if not found
          def fetch_via_direct_api(task_ref)
            begin
              # Get project root from environment or detect it
              root_path = ENV["PROJECT_ROOT_PATH"] || Dir.pwd

              # Use TaskLoader to find task globally (including done tasks)
              loader = Ace::Taskflow::Molecules::TaskLoader.new(root_path)
              task_data = loader.find_task_by_reference(task_ref)

              return task_data
            rescue StandardError
              # Fall back to CLI on any error
              return nil
            end
          end

          # Create TaskMetadata from raw task data
          #
          # @param task_data [Hash] Raw task data from ace-taskflow
          # @param original_ref [String] Original task reference
          # @return [TaskMetadata] Task metadata object
          def create_task_metadata_from_data(task_data, original_ref)
            frontmatter = task_data[:frontmatter] || {}

            TaskMetadata.new(
              id: extract_task_id_from_data(frontmatter, original_ref),
              title: frontmatter["title"] || "Unknown Task",
              description: frontmatter["description"] || "",
              status: frontmatter["status"] || "unknown",
              estimate: frontmatter["estimate"],
              path: task_data[:path],
              raw_data: task_data
            )
          end

          # Extract task ID from task data
          #
          # @param frontmatter [Hash] Task frontmatter
          # @param fallback_ref [String] Original reference as fallback
          # @return [String] Task ID
          def extract_task_id_from_data(frontmatter, fallback_ref)
            # Try to get ID from frontmatter first
            if frontmatter["id"]
              return normalize_task_id_from_frontmatter(frontmatter["id"])
            end

            # Fallback to original reference
            normalize_task_reference(fallback_ref) || fallback_ref
          end

          # Normalize task ID from frontmatter
          #
          # @param id [String] ID from frontmatter (e.g., "v.0.9.0+task.090")
          # @return [String] Normalized task ID (e.g., "090")
          def normalize_task_id_from_frontmatter(id)
            # Extract just the numeric part from various formats
            if id.match?(/\Av\.[\d.]+\+task\.(\d+)\z/)
              id.match(/\Av\.[\d.]+\+task\.(\d+)\z/)[1]
            elsif id.match?(/\A(\d+)\z/)
              id
            else
              # For other formats, try to extract numeric part
              id.scan(/\d+/).last || id
            end
          end

          # Validate task reference for security
          #
          # @param task_ref [String] Task reference to validate
          # @return [Boolean] true if valid
          # @raise [ArgumentError] if task reference is invalid
          def validate_task_reference(task_ref)
            ref = task_ref.to_s.strip

            # Check length
            if ref.length > MAX_TASK_ID_LENGTH
              raise ArgumentError, "Task reference too long: #{ref.length} > #{MAX_TASK_ID_LENGTH}"
            end

            # Check for dangerous patterns
            dangerous_patterns = [
              /[;&|`$(){}\[\]]/,  # Shell metacharacters
              /\x00/,           # Null bytes
              /[\r\n]/,         # Newlines
              /[<>]/,           # Redirects
              /\.\./,           # Directory traversal
            ]

            dangerous_patterns.each do |pattern|
              if ref.match?(pattern)
                raise ArgumentError, "Task reference contains dangerous characters: #{ref.inspect}"
              end
            end

            true
          end

          # Normalize task reference to a standard format
          #
          # @param task_ref [String] Input task reference
          # @return [String, nil] Normalized reference or nil if invalid
          def normalize_task_reference(task_ref)
            ref = task_ref.to_s.strip

            # Validate for security first
            validate_task_reference(ref)

            # Extract numeric ID from various formats
            # Format 1: Just number (081)
            # Format 2: task.number (task.081) or task-number (task-081)
            # Format 3: version+task.number (v.0.9.0+081)
            # Use the same flexible patterns as WorktreeInfo for consistency

            # Try the strict pattern first (for well-formed references)
            match = ref.match(TASK_ID_PATTERN)
            if match
              # Return just the numeric part for ace-taskflow
              return match[3]  # The third capture group is the numeric part
            end

            # Fallback: use the same patterns as WorktreeInfo for consistency
            # Pattern 1: task.081 or task-081
            match = ref.match(/(?:task[.-])?(\d+)/i)
            return match[1] if match

            # Pattern 2: Just a number (for bare task IDs)
            match = ref.match(/^(\d+)$/)
            return match[1] if match

            nil
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

            # Only allow ace-taskflow commands
            allowed_commands = %w[ace-taskflow]
            command_str = command.to_s.strip

            unless allowed_commands.include?(command_str)
              raise ArgumentError, "Command not allowed: #{command_str}"
            end

            # Sanitize arguments
            sanitized_args = []
            args.each do |arg|
              arg_str = arg.to_s.strip

              # Check for dangerous patterns
              dangerous_patterns = [
                /[;&|`$(){}\[\]]/,  # Shell metacharacters
                /\x00/,           # Null bytes
                /[\r\n]/,         # Newlines
                /[<>]/,           # Redirects
              ]

              dangerous_patterns.each do |pattern|
                if arg_str.match?(pattern)
                  raise ArgumentError, "Argument contains dangerous characters: #{arg_str.inspect}"
                end
              end

              sanitized_args << arg_str
            end

            # Build safe command array
            full_command = [command] + sanitized_args
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