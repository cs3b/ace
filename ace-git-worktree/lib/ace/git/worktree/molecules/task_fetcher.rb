# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

# Try to require ace-task API for direct integration (organism level only)
begin
  require "ace/task/organisms/task_manager"
rescue LoadError
  # ace-task not available
end

module Ace
  module Git
    module Worktree
      module Molecules
        # Task fetcher molecule
        #
        # Fetches task data from ace-task by delegating to its TaskManager.
        # Uses organism-level API which handles all path resolution internally.
        #
        # @example Fetch task data
        #   fetcher = TaskFetcher.new
        #   task = fetcher.fetch("8pp.t.q7w")
        #   task[:title] # => "Fix authentication bug"
        #
        # @example Handle non-existent task
        #   task = fetcher.fetch("999")
        #   task # => nil
        class TaskFetcher
          # Initialize a new TaskFetcher
          #
          # TaskManager handles all path resolution internally, no configuration needed.
          def initialize
            # TaskManager handles all path resolution internally
          end

          # Fetch task data by reference
          #
          # @param task_ref [String] Task reference (e.g., "8pp.t.q7w", "081")
          # @return [Hash, nil] Task data hash or nil if not found
          def fetch(task_ref)
            return nil if task_ref.nil? || task_ref.empty?

            # Validate basic input for security
            return nil unless valid_task_reference?(task_ref)

            # Try organism-level API first (preferred)
            if ace_task_available?
              begin
                manager = Ace::Task::Organisms::TaskManager.new
                result = manager.show(task_ref)
                puts "DEBUG: TaskManager result: #{result.inspect}" if ENV["DEBUG"]
                return task_to_hash(result) if result
              rescue => e
                puts "DEBUG: TaskManager exception: #{e.message}" if ENV["DEBUG"]
                puts "DEBUG: Backtrace: #{e.backtrace.first(3).join(", ")}" if ENV["DEBUG"]
                # Fall through to CLI approach
              end
            end

            # Fallback to CLI-based approach
            puts "DEBUG: Falling back to CLI for task #{task_ref}" if ENV["DEBUG"]
            fetch_via_cli(task_ref)
          end

          # Check if ace-task is available
          #
          # @return [Boolean] true if ace-task API is available
          def ace_task_available?
            defined?(Ace::Task::Organisms::TaskManager)
          end

          # Get helpful error message when ace-task is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def ace_task_unavailable_message
            <<~MESSAGE
              ace-task is not available.

              Required for task-aware worktree operations.

              In a mono-repo environment, ensure ace-task is in your Gemfile.
              For standalone installation:
              1. Install ace-task gem: gem install ace-task

              For more information: https://github.com/cs3b/ace
            MESSAGE
          end

          private

          # Convert a Task struct to a hash for backwards compatibility
          #
          # @param task [Ace::Task::Models::Task] Task struct
          # @return [Hash] Task data hash
          def task_to_hash(task)
            {
              id: task.id,
              title: task.title,
              status: task.status,
              path: task.file_path,
              task_number: Atoms::TaskIDExtractor.extract({id: task.id}),
              metadata: task.respond_to?(:metadata) ? (task.metadata || {}) : {}
            }
          end

          # Basic validation for task references
          #
          # @param task_ref [String] Task reference to validate
          # @return [Boolean] true if valid
          def valid_task_reference?(task_ref)
            ref = task_ref.to_s.strip

            # Check for dangerous patterns
            dangerous_patterns = [
              /[;&|`$(){}\[\]]/,  # Shell metacharacters
              /\x00/,           # Null bytes
              /[\r\n]/,         # Newlines
              /[<>]/,           # Redirects
              /\.\./           # Directory traversal
            ]

            return false if ref.length > 50
            return false if dangerous_patterns.any? { |pattern| ref.match?(pattern) }

            true
          end

          # Fetch task via CLI (fallback when API fails)
          #
          # @param task_ref [String] Task reference
          # @return [Hash, nil] Task data hash or nil if not found
          def fetch_via_cli(task_ref)
            require "open3"

            begin
              # Use ace-task CLI to get task data (runs in current directory)
              cmd = ["bundle", "exec", "ace-task", "show", task_ref.to_s]
              stdout, _, status = Open3.capture3(*cmd)

              return nil unless status.success?

              # Parse CLI output to extract task information
              parse_cli_output(stdout)
            rescue => e
              puts "DEBUG: CLI exception: #{e.message}" if ENV["DEBUG"]
              nil
            end
          end

          # Parse CLI output to extract task data
          #
          # @param output [String] CLI output from ace-task
          # @return [Hash, nil] Task data hash or nil
          def parse_cli_output(output)
            lines = output.split("\n")

            # Extract basic task information
            task_data = {
              title: nil,
              status: nil,
              id: nil,
              task_number: nil,
              path: nil,
              metadata: {}
            }

            current_section = nil
            content_lines = []

            lines.each do |line|
              line = line.strip

              # Parse header information
              if line.start_with?("Task: ")
                task_data[:id] = line.sub(/^Task:\s+/, "")
              elsif line.start_with?("Title: ")
                task_data[:title] = line.sub(/^Title:\s+/, "")
              elsif line.start_with?("Status: ")
                # Extract just the status text (remove emoji)
                status_text = line.sub(/^Status:\s+/, "").gsub(/^[^\w]+\s+/, "")
                task_data[:status] = status_text
              elsif line.start_with?("Priority: ")
                task_data[:metadata]["priority"] = line.sub(/^Priority:\s+/, "")
              elsif line.start_with?("Estimate: ")
                task_data[:metadata]["estimate"] = line.sub(/^Estimate:\s+/, "")
              elsif line.start_with?("Path: ")
                task_data[:path] = line.sub(/^Path:\s+/, "")
              elsif line == "--- Content ---"
                current_section = :content
                next
              elsif current_section == :content
                content_lines << line
              end
            end

            # Set content
            task_data[:content] = content_lines.join("\n").strip
            task_data[:metadata]["status"] = task_data[:status] if task_data[:status]

            # Derive task_number using shared extractor (handles subtasks correctly)
            task_data[:task_number] = Atoms::TaskIDExtractor.extract(task_data)

            # Validate that we have the minimum required information
            return nil unless task_data[:id] && task_data[:title]

            task_data
          end
        end

        public

        # Get helpful error message when ace-task is unavailable
        #
        # @return [String] User-friendly error message with installation guidance
        def ace_task_unavailable_message
          <<~MESSAGE
            ace-task is not available.

            Required for task-aware worktree operations.

            In a mono-repo environment, ensure ace-task is in your Gemfile.
            For standalone installation:
            1. Install ace-task gem: gem install ace-task

            For more information: https://github.com/cs3b/ace
          MESSAGE
        end

        # Check availability and return helpful error if unavailable
        #
        # @return [Hash] { available: boolean, message: string }
        def check_availability_with_message
          if ace_task_available?
            # API is available - this is the preferred method in mono-repo
            {available: true, message: "ace-task API is available"}
          else
            {available: false, message: ace_task_unavailable_message}
          end
        end
      end
    end
  end
end
