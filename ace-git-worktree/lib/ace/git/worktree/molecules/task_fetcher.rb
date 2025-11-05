# frozen_string_literal: true

# Try to require ace-taskflow API for direct integration
begin
  require "ace/taskflow/molecules/task_loader"
rescue LoadError
  # ace-taskflow not available
end

module Ace
  module Git
    module Worktree
      module Molecules
        # Task fetcher molecule
        #
        # Fetches task data from ace-taskflow by delegating to its TaskLoader.
        # Provides a simple interface for retrieving task information.
        #
        # @example Fetch task data
        #   fetcher = TaskFetcher.new
        #   task = fetcher.fetch("081")
        #   task[:title] # => "Fix authentication bug"
        #
        # @example Handle non-existent task
        #   task = fetcher.fetch("999")
        #   task # => nil
        class TaskFetcher
          # Initialize a new TaskFetcher
          #
          # @param root_path [String] Project root path (optional, defaults to current dir)
          def initialize(root_path: nil)
            @root_path = root_path || ENV["PROJECT_ROOT_PATH"] || Dir.pwd
          end

          # Fetch task data by reference
          #
          # @param task_ref [String] Task reference (081, task.081, v.0.9.0+081)
          # @return [Hash, nil] Task data hash or nil if not found
          #
          # @example
          #   fetcher = TaskFetcher.new
          #   task = fetcher.fetch("081")
          #   task = fetcher.fetch("task.081")
          #   task = fetcher.fetch("v.0.9.0+081")
          def fetch(task_ref)
            return nil if task_ref.nil? || task_ref.empty?

            # Validate basic input for security
            return nil unless valid_task_reference?(task_ref)

            # Try direct API first
            if ace_taskflow_available?
              begin
                loader = Ace::Taskflow::Molecules::TaskLoader.new(@root_path)
                result = loader.find_task_by_reference(task_ref)
                puts "DEBUG: TaskLoader result: #{result.inspect}" if ENV["DEBUG"]
                return result if result
              rescue StandardError => e
                puts "DEBUG: TaskLoader exception: #{e.message}" if ENV["DEBUG"]
                puts "DEBUG: Backtrace: #{e.backtrace.first(3).join(', ')}" if ENV["DEBUG"]
                # Fall through to CLI approach
              end
            end

            # Fallback to CLI-based approach
            puts "DEBUG: Falling back to CLI for task #{task_ref}" if ENV["DEBUG"]
            fetch_via_cli(task_ref)
          end

          # Check if ace-taskflow is available
          #
          # @return [Boolean] true if ace-taskflow API is available
          def ace_taskflow_available?
            defined?(Ace::Taskflow::Molecules::TaskLoader)
          end

          # Get helpful error message when ace-taskflow is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def ace_taskflow_unavailable_message
            <<~MESSAGE
              ace-taskflow is not available.

              Required for task-aware worktree operations.

              In a mono-repo environment, ensure ace-taskflow is in your Gemfile.
              For standalone installation:
              1. Install ace-taskflow gem: gem install ace-taskflow

              For more information: https://github.com/cs3b/ace-meta
            MESSAGE
          end

          private

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
              /\.\./,           # Directory traversal
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
              # Use ace-taskflow CLI to get task data
              cmd = ["bundle", "exec", "ace-taskflow", "task", "show", task_ref.to_s, "--content"]
              stdout, stderr, status = Open3.capture3(*cmd, chdir: @root_path)

              return nil unless status.success?

              # Parse CLI output to extract task information
              parse_cli_output(stdout)
            rescue StandardError => e
              puts "DEBUG: CLI exception: #{e.message}" if ENV["DEBUG"]
              nil
            end
          end

          # Parse CLI output to extract task data
          #
          # @param output [String] CLI output from ace-taskflow
          # @return [Hash, nil] Task data hash or nil
          def parse_cli_output(output)
            lines = output.split("\n")

            # Extract basic task information
            task_data = {
              title: nil,
              status: nil,
              id: nil,
              task_number: nil,
              release: nil,
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
                # Extract task number from ID
                if match = task_data[:id].match(/task\.(\d+)$/)
                  task_data[:task_number] = match[1]
                end
                # Extract release from ID
                if match = task_data[:id].match(/^(v\.[\d.]+)\+task\./)
                  task_data[:release] = match[1]
                end
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

            # Validate that we have the minimum required information
            return nil unless task_data[:id] && task_data[:title]

            task_data
          end
        end

        public

        # Get helpful error message when ace-taskflow is unavailable
        #
        # @return [String] User-friendly error message with installation guidance
        def ace_taskflow_unavailable_message
          <<~MESSAGE
            ace-taskflow is not available.

            Required for task-aware worktree operations.

            In a mono-repo environment, ensure ace-taskflow is in your Gemfile.
            For standalone installation:
            1. Install ace-taskflow gem: gem install ace-taskflow

            For more information: https://github.com/cs3b/ace-meta
          MESSAGE
        end

        # Check availability and return helpful error if unavailable
        #
        # @return [Hash] { available: boolean, message: string }
        def check_availability_with_message
          if ace_taskflow_available?
            # API is available - this is the preferred method in mono-repo
            { available: true, message: "ace-taskflow API is available" }
          else
            { available: false, message: ace_taskflow_unavailable_message }
          end
        end
      end
    end
  end
end