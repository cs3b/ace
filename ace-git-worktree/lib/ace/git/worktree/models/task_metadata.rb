# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Task metadata model
        #
        # Represents metadata about a task fetched from ace-taskflow,
        # including the task ID, title, status, and derived information
        # such as slugs for naming conventions.
        #
        # @example Create from ace-taskflow output
        #   metadata = TaskMetadata.from_ace_taskflow_output(yaml_string)
        #
        # @example Create manually
        #   metadata = TaskMetadata.new(
        #     id: "081",
        #     task_id: "task.081",
        #     title: "Fix authentication bug",
        #     status: "pending",
        #     release: "v.0.9.0"
        #   )
        class TaskMetadata
          attr_reader :id, :task_id, :title, :status, :priority, :estimate, :release, :dependencies, :slug, :path, :description, :branch

          # Initialize a new TaskMetadata
          #
          # @param id [String] Numeric task ID (e.g., "081")
          # @param task_id [String] Full task ID (e.g., "task.081")
          # @param title [String] Task title
          # @param status [String] Task status (pending, in-progress, done, blocked)
          # @param priority [String, nil] Task priority (high, medium, low)
          # @param estimate [String, nil] Time estimate
          # @param release [String] Release version (e.g., "v.0.9.0")
          # @param dependencies [Array<String>] List of dependency task IDs
          # @param slug [String, nil] URL-safe slug (generated if nil)
          def initialize(id:, task_id:, title:, status:, priority: nil, estimate: nil, release: nil, dependencies: [], slug: nil, branch: nil)
            @id = id.to_s
            @task_id = task_id.to_s
            @title = title.to_s
            @status = status.to_s
            @priority = priority&.to_s
            @estimate = estimate&.to_s
            @release = release&.to_s
            @dependencies = Array(dependencies).map(&:to_s)
            @slug = slug || generate_slug
            @branch = branch
          end

          # Check if the task is in a workable state
          #
          # @return [Boolean] true if task can be worked on
          def workable?
            @status != "done" && @status != "blocked"
          end

          # Check if the task is already in progress
          #
          # @return [Boolean] true if task status is in-progress
          def in_progress?
            @status == "in-progress"
          end

          # Check if the task has high priority
          #
          # @return [Boolean] true if priority is high
          def high_priority?
            @priority == "high"
          end

          # Get the full task reference
          #
          # @return [String] Full reference like "v.0.9.0+task.081"
          def full_reference
            return @task_id unless @release

            "#{@release}+#{@task_id}"
          end

          # Get a short description for display
          #
          # @return [String] Short description
          def short_description
            if @title.length > 50
              "#{@id}: #{@title[0, 47]}..."
            else
              "#{@id}: #{@title}"
            end
          end

          # Parse task metadata from ace-taskflow CLI output
          #
          # @param output [String] Output from `ace-taskflow task show <ref> --content`
          # @return [TaskMetadata, nil] Parsed metadata or nil if parsing failed
          #
          # @example
          #   output = `ace-taskflow task show 081 --content`
          #   metadata = TaskMetadata.from_ace_taskflow_output(output)
          def self.from_ace_taskflow_output(output)
            puts "DEBUG: === TaskMetadata.from_ace_taskflow_output START ===" if ENV["DEBUG"]
            puts "DEBUG: TaskMetadata.from_ace_taskflow_output called with #{output.length} chars" if ENV["DEBUG"]
            puts "DEBUG: First 200 chars: #{output[0, 200].inspect}" if ENV["DEBUG"]
            return nil if output.nil? || output.empty?
            puts "DEBUG: About to call parse_ace_taskflow_cli_output" if ENV["DEBUG"]

            # ace-taskflow outputs human-readable format, not YAML frontmatter
            # Parse the CLI format into structured data (inline implementation)
            puts "DEBUG: Starting inline CLI parsing" if ENV["DEBUG"]
            data = {}

            begin
              output.each_line do |line|
                line = line.strip
                next if line.empty?
                break if line == "--- Content ---"

                if line.include?(':')
                  key, value = line.split(':', 2).map(&:strip)
                  key = key.gsub(/[^\w\s]/, '')
                  value = value.strip

                  case key.downcase
                  when 'task'
                    # Extract ID inline (from extract_id_from_task_value logic)
                    if value.match?(/\Av\.[\d.]+\+task\.(\d+)\z/)
                      data['id'] = value.match(/\Av\.[\d.]+\+task\.(\d+)\z/)[1]
                    else
                      data['id'] = value.scan(/\d+/).last
                    end
                  when 'status'
                    data['status'] = value.gsub(/[^\w\s]/, '').downcase
                  when 'estimate'
                    data['estimate'] = value
                  when 'priority'
                    data['priority'] = value
                  when 'dependencies'
                    data['dependencies'] = value.split(',').map(&:strip).reject(&:empty?)
                  when 'path'
                    data['path'] = value
                  when 'title'
                    data['title'] = value
                  else
                    data[key.downcase] = value
                  end
                end
              end
            rescue StandardError => e
              puts "DEBUG: Inline parsing exception: #{e.message}" if ENV["DEBUG"]
              puts "DEBUG: Inline parsing backtrace: #{e.backtrace.first(3).join(', ')}" if ENV["DEBUG"]
              return nil
            end

            puts "DEBUG: Inline parsing result: #{data.inspect}" if ENV["DEBUG"]
            return nil unless data.is_a?(Hash)

            # Extract task ID from various formats
            puts "DEBUG: About to extract ID from data: #{data.inspect}" if ENV["DEBUG"]
            # Inline extract_id_from_data logic
            id = nil
            if data["id"]
              id = data["id"].to_s
            elsif data["task_id"]
              match = data["task_id"].match(/(\d+)/)
              id = match[1] if match
            elsif data["id"]
              match = data["id"].match(/(\d+)/)
              id = match[1] if match
            end
            puts "DEBUG: Extracted ID: #{id.inspect}" if ENV["DEBUG"]
            return nil unless id

            # Extract other fields
            task_id = data["id"] || "task.#{id}"
            title = data["title"] || "Task #{id}"
            status = data["status"] || "pending"
            priority = data["priority"]
            estimate = data["estimate"]
            # Inline extract_release_from_data logic
            release = nil
            if data["release"]
              release = data["release"]
            elsif data["id"]
              match = data["id"].match(/^(v\.[\d.]+)\+/)
              release = match[1] if match
            end
            dependencies = Array(data["dependencies"])

            puts "DEBUG: About to create TaskMetadata with: id=#{id}, task_id=#{task_id}, title=#{title}" if ENV["DEBUG"]

            begin
              result = new(
                id: id,
                task_id: task_id,
                title: title,
                status: status,
                priority: priority,
                estimate: estimate,
                release: release,
                dependencies: dependencies,
                slug: "task-#{id}",
                branch: nil  # Completed tasks don't have worktree branches
              )

              puts "DEBUG: TaskMetadata created successfully: #{result.inspect}" if ENV["DEBUG"]
              result
            rescue StandardError => e
              puts "DEBUG: TaskMetadata creation exception: #{e.message}" if ENV["DEBUG"]
              puts "DEBUG: TaskMetadata creation backtrace: #{e.backtrace.first(3).join(', ')}" if ENV["DEBUG"]
              nil
            end
          rescue StandardError
            nil
            end
          end

          # Create from task ID by fetching from ace-taskflow
          #
          # @param task_ref [String] Task reference (081, task.081, v.0.9.0+081)
          # @return [TaskMetadata, nil] Task metadata or nil if not found
          #
          # @example
          #   metadata = TaskMetadata.fetch("081")
          #   metadata = TaskMetadata.fetch("task.081")
          #   metadata = TaskMetadata.fetch("v.0.9.0+081")
          def self.fetch(task_ref)
            require "open3"

            # Try to fetch from ace-taskflow CLI
            stdout, stderr, status = Open3.capture3("ace-taskflow", "task", "show", task_ref.to_s, "--content")
            return nil unless status.success?

            from_ace_taskflow_output(stdout)
          rescue StandardError
            nil
          end

          # Search for tasks by title pattern
          #
          # @param pattern [String] Pattern to search for
          # @param limit [Integer] Maximum number of results
          # @return [Array<TaskMetadata>] Array of matching tasks
          def self.search(pattern, limit: 10)
            require "open3"

            # Try to search using ace-taskflow CLI
            stdout, stderr, status = Open3.capture3("ace-taskflow", "tasks", "--search", pattern.to_s, "--limit", limit.to_s)
            return [] unless status.success?

            # Parse each task from the output
            results = []
            stdout.split("\n").each do |line|
              # Extract task ID from line and fetch full metadata
              task_id_match = line.match(/\b(\d+)\b/)
              next unless task_id_match

              metadata = fetch(task_id_match[1])
              results << metadata if metadata
            end

            results
          rescue StandardError
            []
          end

          # Convert to hash
          #
          # @return [Hash] Task metadata as hash
          def to_h
            {
              id: @id,
              task_id: @task_id,
              title: @title,
              status: @status,
              priority: @priority,
              estimate: @estimate,
              release: @release,
              dependencies: @dependencies.dup,
              slug: @slug,
              workable: workable?,
              in_progress: in_progress?,
              high_priority: high_priority?,
              full_reference: full_reference,
              short_description: short_description
            }
          end

          # Convert to JSON
          #
          # @return [String] JSON representation
          def to_json(*args)
            to_h.to_json(*args)
          end

          # Equality comparison
          #
          # @param other [TaskMetadata] Other task metadata
          # @return [Boolean] true if equal
          def ==(other)
            return false unless other.is_a?(TaskMetadata)

            @id == other.id && @task_id == other.task_id && @release == other.release
          end

          alias eql? ==

          # Hash for using as hash keys
          #
          # @return [Integer] Hash value
          def hash
            [@id, @task_id, @release].hash
          end

          # Get branch associated with this task (if any)
          #
          # @return [String, nil] Branch name or nil for completed tasks
          def branch
            # Completed tasks don't have associated worktree branches
            nil
          end

          # String representation
          #
          # @return [String] String representation
          def to_s
            short_description
          end

          # Inspect representation
          #
          # @return [String] Detailed inspect string
          def inspect
            "#<#{self.class.name} id=#{@id} task_id=#{@task_id} title=#{@title.inspect} status=#{@status.inspect}>"
          end

          # Parse ace-taskflow CLI output format into structured data
          #
          # @param output [String] CLI output from ace-taskflow task show --content
          # @return [Hash, nil] Parsed data hash or nil if parsing fails
          def self.parse_ace_taskflow_cli_output(output)
            puts "DEBUG: parse_ace_taskflow_cli_output called" if ENV["DEBUG"]
            data = {}

            output.each_line do |line|
              line = line.strip
              next if line.empty?

              # Stop parsing at "--- Content ---" separator
              break if line == "--- Content ---"

              # Parse key-value pairs (Key: Value)
              if line.include?(':')
                key, value = line.split(':', 2).map(&:strip)

                # Clean up the key (remove special characters)
                key = key.gsub(/[^\w\s]/, '')

                # Clean up the value
                value = value.strip

                # Handle special fields
                case key.downcase
                when 'task'
                  # Extract ID from "Task: v.0.9.0+task.089"
                  data['id'] = extract_id_from_task_value(value)
                when 'status'
                  # Clean up status emoji and convert to string
                  data['status'] = value.gsub(/[^\w\s]/, '').downcase
                when 'estimate'
                  data['estimate'] = value
                when 'priority'
                  data['priority'] = value
                when 'dependencies'
                  # Parse comma-separated dependencies
                  data['dependencies'] = value.split(',').map(&:strip).reject(&:empty?)
                when 'path'
                  data['path'] = value
                when 'title'
                  data['title'] = value
                else
                  data[key.downcase] = value
                end
              end
            end

            data
          end

          # Extract task ID from task value like "v.0.9.0+task.089"
          #
          # @param task_value [String] Task value from CLI output
          # @return [String, nil] Extracted task ID
          def self.extract_id_from_task_value(task_value)
            # Extract just the numeric part from formats like "v.0.9.0+task.089"
            if task_value.match?(/\Av\.[\d.]+\+task\.(\d+)\z/)
              task_value.match(/\Av\.[\d.]+\+task\.(\d+)\z/)[1]
            else
              # For other formats, try to extract numeric part
              task_value.scan(/\d+/).last
            end
          end

          private

          # Generate a URL-safe slug from the title
          #
          # @return [String] Generated slug
          def generate_slug
            require_relative "../atoms/slug_generator"
            Atoms::SlugGenerator.from_title(@title)
          end

          # Extract numeric ID from task data
          #
          # @param data [Hash] Task data
          # @return [String, nil] Extracted ID or nil
          def self.extract_id_from_data(data)
            # Try direct ID field
            return data["id"].to_s if data["id"]

            # Try to extract from task_id field
            if data["task_id"]
              match = data["task_id"].match(/(\d+)/)
              return match[1] if match
            end

            # Try to extract from full id field
            if data["id"]
              match = data["id"].match(/(\d+)/)
              return match[1] if match
            end

            nil
          end

          # Extract title from markdown content
          #
          # @param content [String] Markdown content
          # @return [String, nil] Extracted title or nil
          def self.extract_title_from_content(content)
            return nil if content.nil? || content.empty?

            # Try to extract first heading
            heading_match = content.match(/^#\s+(.+)$/m)
            return heading_match[1].strip if heading_match

            # Try to extract from first line if it looks like a title
            first_line = content.split("\n").first&.strip
            return first_line if first_line && first_line.length < 100 && !first_line.start_with?("#")

            nil
          end

          # Extract release from task data
          #
          # @param data [Hash] Task data
          # @return [String, nil] Extracted release or nil
          def self.extract_release_from_data(data)
            # Try direct release field
            return data["release"] if data["release"]

            # Try to extract from full id field
            if data["id"]
              match = data["id"].match(/^(v\.[\d.]+)\+/)
              return match[1] if match
            end

            nil
          end
        end
      end
    end
  end
