# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/task_id_parser"
require_relative "../../atoms/taskflow_management/file_system_scanner"
require_relative "../../atoms/taskflow_management/yaml_frontmatter_parser"

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskIdGenerator composes atoms to provide task ID generation functionality
      class TaskIdGenerator
        # Generation result
        GenerationResult = Struct.new(:task_id, :version, :sequential_number, :success, :error_message) do
          def success?
            success
          end
        end

        # Generate next task ID for a release directory
        def self.generate_next_task_id(release_path, version: nil)
          version = extract_version_from_directory(release_path) if version.nil?
          return GenerationResult.new(nil, nil, nil, false, "Could not extract version") unless version

          max_number = find_max_task_number(release_path, version)
          next_number = max_number + 1
          task_id = Atoms::TaskflowManagement::TaskIdParser.generate_next_id(version, current_max: max_number)

          GenerationResult.new(task_id, version, next_number, true, nil)
        rescue => e
          GenerationResult.new(nil, version, nil, false, "Error generating task ID: #{e.message}")
        end

        # Get existing task IDs in a release
        def self.get_existing_task_ids(release_path, version: nil)
          return [] if release_path.nil? || release_path.empty?

          task_ids = []
          tasks_dir = File.join(release_path, "tasks")
          return task_ids unless File.exist?(tasks_dir) && File.directory?(tasks_dir)

          task_files = Atoms::TaskflowManagement::FileSystemScanner.find_files_by_extension(
            tasks_dir, ".md", recursive: false
          )

          task_files.each do |relative_path|
            absolute_path = File.join(tasks_dir, relative_path)
            parse_result = Atoms::TaskflowManagement::YamlFrontmatterParser.parse_file(absolute_path)
            next unless parse_result.has_frontmatter?

            task_id = parse_result.frontmatter["id"]
            next unless task_id&.is_a?(String)

            if version.nil? || Atoms::TaskflowManagement::TaskIdParser.belongs_to_version?(task_id, version)
              task_ids << task_id if Atoms::TaskflowManagement::TaskIdParser.valid?(task_id)
            end
          rescue => e
            warn "Warning: Could not parse task file #{relative_path}: #{e.message}"
          end

          task_ids
        end

        class << self
          private

          def extract_version_from_directory(release_path)
            dir_name = File.basename(release_path)
            match = dir_name.match(/^(v\.\d+\.\d+\.\d+)/)
            match ? match[1] : nil
          end

          def find_max_task_number(release_path, version)
            task_ids = get_existing_task_ids(release_path, version: version)
            return 0 if task_ids.empty?

            sequential_numbers = task_ids.map do |task_id|
              Atoms::TaskflowManagement::TaskIdParser.extract_sequential_number(task_id)
            rescue
              0
            end

            sequential_numbers.max || 0
          end
        end
      end
    end
  end
end