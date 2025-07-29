# frozen_string_literal: true

require "dry/cli"
require_relative "../../../atoms/project_root_detector"
require_relative "../../../molecules/taskflow_management/release_resolver"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # GenerateId command for generating new task IDs
        class GenerateId < Dry::CLI::Command
          desc "Generate new task ID(s) for the current release"

          argument :version, required: false, desc: "Version string (e.g., 'v.0.3.0'). If not provided, detects from current release"

          option :limit, type: :integer, default: 1,
            desc: "Number of task IDs to generate (default: 1)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :release, type: :string,
            desc: "Release to work with (version, codename, fullname, or path). Defaults to current release."

          example [
            "",
            "v.0.3.0",
            "--limit 3",
            "v.0.3.0 --limit 5",
            "--debug"
          ]

          def call(version: nil, **options)
            limit = validate_limit(options[:limit]) if options[:limit]
            limit ||= options[:limit] || 1

            release_version = version || detect_version_from_release(options[:release])

            unless release_version
              error_output("Error: Could not determine release version. Please provide version argument or --release option.")
              return 1
            end

            next_task_number = find_next_task_number(release_version)
            generate_task_ids(release_version, next_task_number, limit)
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def validate_limit(limit)
            limit_int = limit.to_i
            unless limit_int.positive?
              raise ArgumentError, "Limit must be a positive integer, got: #{limit}"
            end
            limit_int
          end

          def detect_version_from_release(release_identifier)
            if release_identifier
              # Use release resolver to find the specified release
              project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
              result = CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver.resolve_release(
                release_identifier,
                base_path: project_root
              )

              if result.success?
                result.release_info.version
              else
                error_output("Error resolving release '#{release_identifier}': #{result.error_message}")
                nil
              end
            else
              # Fall back to current version detection
              detect_current_version
            end
          end

          def detect_current_version
            # Try to detect version from current release directory
            current_release_path = find_current_release_directory
            return nil unless current_release_path

            # Extract version from directory name
            dir_name = File.basename(current_release_path)
            if dir_name =~ /^(v\.\d+\.\d+\.\d+)/
              $1
            elsif dir_name =~ /^(v\.\d+\.\d+)/
              $1
            end
          end

          def find_current_release_directory
            # Look for current release directory
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            current_dir = File.join(project_root, "dev-taskflow", "current")
            return nil unless File.exist?(current_dir)

            # Find the first directory that looks like a release
            Dir.glob(File.join(current_dir, "*")).find do |path|
              File.directory?(path) && File.basename(path).match?(/^v\.\d+\.\d+/)
            end
          end

          def find_next_task_number(version)
            # Find existing task files and determine next number
            release_dir = find_release_directory(version)
            return 1 unless release_dir

            tasks_dir = File.join(release_dir, "tasks")
            return 1 unless File.exist?(tasks_dir)

            # Find all task files and extract numbers
            task_files = Dir.glob(File.join(tasks_dir, "*.md"))

            max_number = 0
            task_files.each do |file|
              basename = File.basename(file, ".md")
              if basename =~ /#{Regexp.escape(version)}\+task\.(\d+)/
                task_num = $1.to_i
                max_number = [max_number, task_num].max
              end
            end

            max_number + 1
          end

          def find_release_directory(version)
            # Look in both current and done directories
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            search_dirs = [
              File.join(project_root, "dev-taskflow", "current"),
              File.join(project_root, "dev-taskflow", "done")
            ]

            search_dirs.each do |base_dir|
              next unless File.exist?(base_dir)

              Dir.glob(File.join(base_dir, "*")).each do |path|
                next unless File.directory?(path)

                dir_name = File.basename(path)
                if dir_name.include?(version)
                  return path
                end
              end
            end

            nil
          end

          def generate_task_ids(version, start_number, count)
            if count == 1
              puts "#{version}+task.#{start_number.to_s.rjust(3, "0")}"
            else
              puts "Generated #{count} task IDs:"
              count.times do |i|
                task_number = start_number + i
                puts "  #{version}+task.#{task_number.to_s.rjust(3, "0")}"
              end
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
            end
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end
