# frozen_string_literal: true

require_relative "../models/task_metadata"

module Ace
  module Git
    module Worktree
      module Molecules
        # Fetches task metadata from ace-taskflow
        class TaskFetcher
          # Fetch task metadata by reference
          # @param reference [String] Task reference (081, task.081, v.0.9.0+task.081)
          # @return [Models::TaskMetadata, nil] Task metadata or nil if not found
          def self.fetch(reference)
            return nil if reference.nil? || reference.empty?

            # Try to fetch task metadata using ace-taskflow
            result = execute_taskflow("task", reference, "--content")

            if result[:success]
              # Parse the output to create TaskMetadata
              metadata = Models::TaskMetadata.from_taskflow_output(result[:output])

              # If we got metadata but no path, try to get the path separately
              if metadata && !metadata.path
                path_result = execute_taskflow("task", reference, "--path")
                if path_result[:success]
                  metadata = Models::TaskMetadata.new(
                    id: metadata.id,
                    full_id: metadata.full_id,
                    release: metadata.release,
                    number: metadata.number,
                    title: metadata.title,
                    status: metadata.status,
                    priority: metadata.priority,
                    estimate: metadata.estimate,
                    dependencies: metadata.dependencies,
                    path: path_result[:output].strip
                  )
                end
              end

              metadata
            else
              # Try simpler approach - just get the task info
              simple_result = execute_taskflow("task", reference)
              if simple_result[:success]
                parse_simple_output(simple_result[:output])
              else
                nil
              end
            end
          end

          # Check if ace-taskflow is available
          # @return [Boolean] true if ace-taskflow command exists
          def self.available?
            result = execute_taskflow("--version")
            result[:success]
          end

          # List all tasks
          # @param options [Hash] Options for listing
          # @return [Array<Models::TaskMetadata>] List of tasks
          def self.list(options = {})
            cmd_args = ["tasks"]
            cmd_args << "all" if options[:all]
            cmd_args << "--limit" << options[:limit].to_s if options[:limit]

            result = execute_taskflow(*cmd_args)
            return [] unless result[:success]

            parse_list_output(result[:output])
          end

          private

          # Execute ace-taskflow command
          def self.execute_taskflow(*args)
            require 'open3'

            cmd_array = ["ace-taskflow", *args]

            begin
              stdout, stderr, status = Open3.capture3(*cmd_array)
              {
                success: status.success?,
                output: stdout,
                error: stderr,
                exit_code: status.exitstatus
              }
            rescue Errno::ENOENT
              # Command not found
              {
                success: false,
                output: "",
                error: "ace-taskflow command not found. Please install the ace-taskflow gem.",
                exit_code: 127
              }
            rescue => e
              {
                success: false,
                output: "",
                error: "Failed to execute ace-taskflow: #{e.message}",
                exit_code: -1
              }
            end
          end

          # Parse simple task output
          def self.parse_simple_output(output)
            # Expected format:
            # Task: v.0.9.0+task.081 ⚪ Fix authentication bug
            #   Path: .ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md
            #   Estimate: 2h | Dependencies: task.080

            lines = output.lines.map(&:strip)
            return nil if lines.empty?

            # Parse first line
            if lines[0] =~ /Task:\s+(v\.[^+]+\+task\.\d+)\s+[⚫⚪🟡🟢🔴]\s+(.+)$/
              id = $1
              title = $2

              # Parse ID components
              release = nil
              number = nil
              if id =~ /^(v\.[^+]+)\+task\.(\d+)$/
                release = $1
                number = $2
              end

              # Parse additional lines for path and other metadata
              path = nil
              estimate = nil
              dependencies = []

              lines[1..-1].each do |line|
                case line
                when /Path:\s+(.+)$/
                  path = $1
                when /Estimate:\s+([^|]+)/
                  estimate = $1.strip
                when /Dependencies:\s+(.+)$/
                  deps = $1.strip
                  dependencies = deps.split(/,\s*/) unless deps == "none"
                end
              end

              Models::TaskMetadata.new(
                id: id,
                full_id: id,
                release: release,
                number: number,
                title: title,
                path: path,
                estimate: estimate,
                dependencies: dependencies
              )
            else
              nil
            end
          end

          # Parse list output
          def self.parse_list_output(output)
            tasks = []

            output.lines.each do |line|
              # Look for task lines with status icons
              if line =~ /^\s*(v\.[^+]+\+task\.\d+)\s+[⚫⚪🟡🟢🔴]\s+(.+)$/
                id = $1
                title = $2.strip

                # Parse ID components
                release = nil
                number = nil
                if id =~ /^(v\.[^+]+)\+task\.(\d+)$/
                  release = $1
                  number = $2
                end

                tasks << Models::TaskMetadata.new(
                  id: id,
                  full_id: id,
                  release: release,
                  number: number,
                  title: title
                )
              end
            end

            tasks
          end
        end
      end
    end
  end
end