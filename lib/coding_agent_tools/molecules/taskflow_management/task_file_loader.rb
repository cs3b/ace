# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/file_system_scanner"
require_relative "../../atoms/taskflow_management/yaml_frontmatter_parser"

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskFileLoader composes atoms to provide task file loading functionality
      class TaskFileLoader
        # Task data structure
        TaskData = Struct.new(:id, :status, :dependencies, :title, :path, :frontmatter, :content)

        # Load result
        LoadResult = Struct.new(:tasks, :errors, :warnings)

        # Load tasks from a single file
        def self.load_task_file(file_path)
          parse_result = Atoms::TaskflowManagement::YamlFrontmatterParser.parse_file(file_path)
          return nil unless parse_result.has_frontmatter?

          frontmatter = parse_result.frontmatter
          content = parse_result.content

          id = frontmatter["id"]
          status = frontmatter["status"]
          return nil unless id && status

          dependencies = frontmatter["dependencies"] || []
          title = extract_title_from_content(content)

          TaskData.new(id, status, dependencies, title, file_path, frontmatter, content)
        rescue => e
          warn "Warning: Failed to parse task file #{file_path}: #{e.message}"
          nil
        end

        # Load tasks from directory
        def self.load_tasks_from_directory(directory_path, recursive: false, max_files: 1000)
          errors = []
          warnings = []
          tasks = []

          task_files = Atoms::TaskflowManagement::FileSystemScanner.scan_directory(
            directory_path, patterns: ["*.md"], recursive: recursive, max_files: max_files
          )

          task_files.each do |relative_path|
            absolute_path = File.join(directory_path, relative_path)
            task_data = load_task_file(absolute_path)
            tasks << task_data if task_data
          end

          LoadResult.new(tasks, errors, warnings)
        rescue => e
          LoadResult.new([], ["Error scanning directory: #{e.message}"], [])
        end

        class << self
          private

          def extract_title_from_content(content)
            return "(No Title)" if content.nil? || content.strip.empty?

            lines = content.split("\n")
            lines.each do |line|
              if line.match?(/^#+\s+(.+)/)
                match = line.match(/^#+\s+(.+)/)
                return match[1].strip
              end
            end

            "(No Title)"
          end
        end
      end
    end
  end
end