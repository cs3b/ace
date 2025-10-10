# frozen_string_literal: true

require "dry/cli"
require "yaml"
require_relative "../../../organisms/taskflow_management/release_manager"
require_relative "../../../organisms/taskflow_management/task_manager"
require_relative "../../../molecules/taskflow_management/release_resolver"
require_relative "../../../molecules/file_io_handler"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # Create command for creating new tasks in the current release
        class Create < Dry::CLI::Command
          desc "Create a new task in the current release"

          option :title, desc: "Task title", required: true
          option :priority, type: :string, values: ["high", "medium", "low"], default: "medium",
            desc: "Priority level for the task"
          option :estimate, type: :string, default: "TBD",
            desc: "Time estimate (e.g., '4h', '2d', 'TBD')"
          option :status, type: :string, values: ["pending", "in-progress", "done", "blocked", "draft"], default: "draft",
            desc: "Initial task status"
          option :release, type: :string,
            desc: "Release to create task in (version, codename, fullname, or path). Defaults to current release."

          example [
            '--title "Implement feature X" --priority high --estimate 4h',
            '--title "Fix bug in authentication" --priority medium --status pending',
            '--title "Research new library" --custom-field "library-name" --another-flag "value"',
            '--release v.0.5.0 --title "Task for specific release"'
          ]

          def call(**options)
            # Initialize components
            @project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            @release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: @project_root)
            @task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: @project_root)
            @file_handler = CodingAgentTools::Molecules::FileIoHandler.new

            # Parse undefined flags from ARGV and merge with options
            undefined_flags = parse_undefined_flags(ARGV)
            enhanced_options = options.merge(undefined_flags)

            # Resolve release if specified
            if options[:release]
              release_result = CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver.resolve_release(
                options[:release],
                base_path: @project_root
              )

              unless release_result.success?
                puts "Error: #{release_result.error_message}"
                return 1
              end

              release_info = release_result.release_info

              # Generate task ID for the specified release
              id_result = @release_manager.generate_id_for_release(release_info)
              unless id_result.success?
                puts "Error: #{id_result.error_message}"
                return 1
              end
              task_id = id_result.data

              # Get tasks directory for the specified release
              tasks_dir = File.join(release_info.path, "tasks")
              unless File.exist?(tasks_dir)
                Dir.mkdir(tasks_dir)
              end
            else
              # Use current release (original behavior)
              # Generate task ID
              id_result = @release_manager.generate_id
              unless id_result.success?
                puts "Error: #{id_result.error_message}"
                return 1
              end
              task_id = id_result.data

              # Get current release path
              begin
                tasks_dir = @release_manager.resolve_path("tasks", create_if_missing: true)
              rescue => e
                puts "Error: #{e.message}"
                return 1
              end
            end

            # Generate filename from title
            filename = generate_filename(enhanced_options[:title], task_id)
            task_path = File.join(tasks_dir, filename)

            # Generate task content
            task_content = generate_task_content(task_id, enhanced_options)

            # Write task file
            begin
              @file_handler.write_content(task_content, task_path, force: false)
              puts "File created successfully"
              puts "Created: #{task_path}"

              # Report dynamic flags that were added
              dynamic_flags = undefined_flags.except(:title, :priority, :estimate, :status)
              unless dynamic_flags.empty?
                flag_summary = dynamic_flags.map { |k, v| "#{k}=#{v}" }.join(", ")
                puts "Added metadata: #{flag_summary}"
              end

              0
            rescue CodingAgentTools::Error => e
              puts "Error: #{e.message}"
              1
            end
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          private

          # Parse undefined flags from ARGV that weren't processed by dry-cli
          # This captures dynamic flags like --custom-field value
          def parse_undefined_flags(argv)
            undefined_flags = {}
            defined_flag_names = ["title", "priority", "estimate", "status", "release"]

            i = 0
            while i < argv.length
              arg = argv[i]

              # Check if this is a flag (starts with --)
              if arg.start_with?("--")
                flag_name = arg.sub(/^--/, "")

                # Skip if this is a defined flag or if it's the command
                if defined_flag_names.include?(flag_name) ||
                    ["create"].include?(arg)
                  i += 1
                  next
                end

                # Look for the value (next argument that doesn't start with --)
                value = nil
                if i + 1 < argv.length && !argv[i + 1].start_with?("--")
                  value = argv[i + 1]
                  i += 2  # Skip both flag and value
                else
                  # Boolean flag with no value
                  value = true
                  i += 1
                end

                # Validate flag name for security
                if validate_flag_name(flag_name)
                  # Convert value to appropriate type and store
                  converted_value = convert_flag_value(value)
                  undefined_flags[flag_name.tr("-", "_").to_sym] = converted_value
                else
                  warn "Warning: Skipped invalid flag name: --#{flag_name}"
                end
              else
                i += 1
              end
            end

            undefined_flags
          rescue => e
            warn "Warning: Error parsing undefined flags: #{e.message}"
            {}
          end

          # Validate flag name for security and conflicts
          def validate_flag_name(flag_name)
            # Check for valid flag name pattern (letters, numbers, hyphens)
            return false unless flag_name.match?(/\A[a-z][a-z0-9\-]*\z/i)

            # Check length limit
            return false if flag_name.length > 50

            # Check for reserved names
            reserved_names = ["help", "version", "debug", "verbose", "quiet"]
            return false if reserved_names.include?(flag_name)

            true
          end

          # Convert flag value to appropriate YAML type
          def convert_flag_value(value)
            return value unless value.is_a?(String)

            # Handle empty strings
            return "" if value.empty?

            # Try boolean conversion first (but be more specific to avoid conflicts with numbers)
            case value.downcase
            when "true", "yes", "on"
              return true
            when "false", "no", "off"
              return false
            when "1", "0"  # Handle numeric booleans separately to avoid conflicts
              # For '1' and '0', prefer integer interpretation unless explicitly boolean context
              return value.to_i
            end

            # Try integer conversion
            if value.match?(/\A-?\d+\z/)
              return value.to_i
            end

            # Try float conversion
            if value.match?(/\A-?\d+\.\d+\z/)
              return value.to_f
            end

            # Handle arrays (comma-separated values)
            if value.include?(",")
              return value.split(",").map(&:strip)
            end

            # Return as string (default)
            value
          end

          def generate_filename(title, task_id)
            # Create a URL-friendly slug from the title
            slug = title.to_s
              .downcase
              .gsub(/[^\w\s-]/, "")
              .gsub(/\s+/, "-")
              .squeeze("-")
              .strip
              .gsub(/^-|-$/, "")

            # Limit slug length to prevent filesystem filename length issues
            max_slug_length = 60
            if slug.length > max_slug_length
              # Find the last word boundary (hyphen) within the limit
              truncated = slug[0, max_slug_length]
              last_hyphen = truncated.rindex("-")

              slug = if last_hyphen && last_hyphen > max_slug_length * 0.7 # Keep at least 70% of desired length
                truncated[0, last_hyphen]
              else
                # Fallback: truncate and clean up
                truncated.gsub(/-+$/, "")
              end
            end

            "#{task_id}-#{slug}.md"
          end

          def generate_task_content(task_id, options)
            # Extract standard metadata
            title = options[:title]
            priority = options[:priority] || "medium"
            estimate = options[:estimate] || "TBD"
            status = options[:status] || "draft"

            # Extract dynamic metadata
            dynamic_metadata = options.except(:title, :priority, :estimate, :status)

            # Load task template if available
            template_content = load_task_template

            if template_content
              # Apply template substitution
              apply_template_substitution(template_content, task_id, title, priority, estimate, status, dynamic_metadata)
            else
              # Generate basic task content
              generate_basic_task_content(task_id, title, priority, estimate, status, dynamic_metadata)
            end
          end

          def load_task_template
            # Try to load template from config
            config_path = File.join(@project_root, ".coding-agent", "task-manager.yml")

            if File.exist?(config_path)
              config = YAML.load_file(config_path)
              template_path = config.dig("templates", "task", "path")

              if template_path && File.exist?(template_path)
                File.read(template_path)
              end
            end
          rescue => e
            warn "Warning: Failed to load task template: #{e.message}"
            nil
          end

          def apply_template_substitution(template, task_id, title, priority, estimate, status, dynamic_metadata)
            result = template.dup

            # Apply standard substitutions
            result = result.gsub("{id}", task_id)
              .gsub("{title}", title)
              .gsub("{priority}", priority)
              .gsub("{estimate}", estimate)
              .gsub("{status}", status)
              .gsub("{date}", Time.now.strftime("%Y-%m-%d"))
              .gsub("{timestamp}", Time.now.strftime("%Y%m%d-%H%M%S"))

            # Apply dynamic metadata substitutions
            dynamic_metadata.each do |key, value|
              result = result.gsub("{#{key}}", value.to_s)
                .gsub("{metadata.#{key}}", value.to_s)
            end

            result
          end

          def generate_basic_task_content(task_id, title, priority, estimate, status, dynamic_metadata)
            content = []
            content << "---"
            content << "id: #{task_id}"
            content << "status: #{status}"
            content << "priority: #{priority}"
            content << "estimate: #{estimate}"
            content << "dependencies: []"

            # Add dynamic metadata to frontmatter
            dynamic_metadata.each do |key, value|
              # Convert key to proper YAML format
              yaml_key = key.to_s.tr("_", "-")

              # Handle different value types
              yaml_value = case value
              when Array
                value.empty? ? "[]" : "\n#{value.map { |v| "  - #{v}" }.join("\n")}"
              when Hash
                value.empty? ? "{}" : "\n#{value.map { |k, v| "  #{k}: #{v}" }.join("\n")}"
              when true, false
                value.to_s
              else
                value.to_s
              end

              content << "#{yaml_key}: #{yaml_value}"
            end

            content << "---"
            content << ""
            content << "# #{title}"
            content << ""
            content << "## Objective"
            content << ""
            content << "<!-- Describe the goal of this task -->"
            content << ""
            content << "## Implementation Plan"
            content << ""
            content << "### Planning Steps"
            content << ""
            content << "* [ ] Research and analyze requirements"
            content << "* [ ] Design solution approach"
            content << ""
            content << "### Execution Steps"
            content << ""
            content << "- [ ] Implement core functionality"
            content << "- [ ] Add tests"
            content << "- [ ] Update documentation"
            content << ""
            content << "## Acceptance Criteria"
            content << ""
            content << "- [ ] Task objectives are met"
            content << "- [ ] Tests pass"
            content << "- [ ] Documentation is updated"
            content << ""

            content.join("\n")
          end
        end
      end
    end
  end
end
