# frozen_string_literal: true

require_relative "../atoms/safe_yaml_parser"

module Ace
  module Taskflow
    module Molecules
      # Validates frontmatter structure and content
      class FrontmatterValidator
        # Validate a file's frontmatter
        # @param file_path [String] Path to the file
        # @param component_type [Symbol] Type of component (:task, :idea, :retro)
        # @return [Hash] Validation result with :valid, :issues, :file_path
        def self.validate_file(file_path, component_type = :auto)
          return { valid: false, issues: [{ type: :error, message: "File not found" }], file_path: file_path } unless File.exist?(file_path)

          content = File.read(file_path)
          component_type = detect_component_type(file_path) if component_type == :auto

          validate_content(content, component_type, file_path)
        end

        # Validate content's frontmatter
        # @param content [String] The content to validate
        # @param component_type [Symbol] Type of component
        # @param file_path [String] Optional file path for context
        # @return [Hash] Validation result
        def self.validate_content(content, component_type, file_path = nil)
          result = Atoms::SafeYamlParser.parse_with_recovery(content)
          issues = []

          # Add any parsing errors and warnings
          result[:errors].each { |e| issues << { type: :error, message: e, file: file_path } }
          result[:warnings].each { |w| issues << { type: :warning, message: w, file: file_path } }

          # Validate based on component type
          frontmatter = result[:frontmatter]
          if frontmatter.is_a?(Hash)
            case component_type
            when :task
              validate_task_frontmatter(frontmatter, issues, file_path)
            when :idea
              validate_idea_frontmatter(frontmatter, issues, file_path)
            when :retro
              validate_retro_frontmatter(frontmatter, issues, file_path)
            when :release
              validate_release_frontmatter(frontmatter, issues, file_path)
            end
          else
            issues << { type: :error, message: "Frontmatter is not a valid hash", file: file_path }
          end

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            file_path: file_path,
            frontmatter: frontmatter,
            recovered: result[:recovered]
          }
        end

        private

        def self.detect_component_type(file_path)
          case file_path
          when /\/t\/.*\.md$/, /task\.\d+\.md$/
            :task
          when /\/ideas\/.*\.md$/
            :idea
          when /\/retros\/.*\.md$/
            :retro
          when /release\.md$/
            :release
          else
            :unknown
          end
        end

        def self.validate_task_frontmatter(frontmatter, issues, file_path)
          # Required fields
          issues << { type: :error, message: "Missing required field: id", file: file_path } unless frontmatter["id"]
          issues << { type: :error, message: "Missing required field: status", file: file_path } unless frontmatter["status"]

          # Validate status values
          if frontmatter["status"]
            valid_statuses = %w[pending in-progress done blocked draft]
            unless valid_statuses.include?(frontmatter["status"])
              issues << { type: :error, message: "Invalid status: #{frontmatter["status"]} (must be one of: #{valid_statuses.join(', ')})", file: file_path }
            end
          end

          # Validate priority values
          if frontmatter["priority"]
            valid_priorities = %w[high medium low]
            unless valid_priorities.include?(frontmatter["priority"])
              issues << { type: :warning, message: "Invalid priority: #{frontmatter["priority"]} (should be one of: #{valid_priorities.join(', ')})", file: file_path }
            end
          else
            issues << { type: :warning, message: "Missing recommended field: priority", file: file_path }
          end

          # Validate ID format
          if frontmatter["id"] && !frontmatter["id"].match?(/^v\.\d+\.\d+\.\d+\+task\.\d+$/)
            issues << { type: :warning, message: "Non-standard ID format: #{frontmatter["id"]} (expected format: v.X.Y.Z+task.NNN)", file: file_path }
          end

          # Validate dependencies
          if frontmatter["dependencies"] && !frontmatter["dependencies"].is_a?(Array)
            issues << { type: :error, message: "Dependencies must be an array", file: file_path }
          end
        end

        def self.validate_idea_frontmatter(frontmatter, issues, file_path)
          # Ideas don't require frontmatter, but if present, validate it
          return if frontmatter.empty?

          # If frontmatter exists, check for common fields
          if frontmatter["status"]
            valid_statuses = %w[pending done]
            unless valid_statuses.include?(frontmatter["status"])
              issues << { type: :warning, message: "Invalid idea status: #{frontmatter["status"]}", file: file_path }
            end
          end
        end

        def self.validate_retro_frontmatter(frontmatter, issues, file_path)
          # Retros typically don't have frontmatter
          # Just check if it's present and valid YAML
        end

        def self.validate_release_frontmatter(frontmatter, issues, file_path)
          # Validate release metadata if present
          if frontmatter["version"] && !frontmatter["version"].match?(/^v\.\d+\.\d+\.\d+$/)
            issues << { type: :warning, message: "Non-standard version format: #{frontmatter["version"]}", file: file_path }
          end

          if frontmatter["status"]
            valid_statuses = %w[active backlog done]
            unless valid_statuses.include?(frontmatter["status"])
              issues << { type: :warning, message: "Invalid release status: #{frontmatter["status"]}", file: file_path }
            end
          end
        end

        # Batch validate multiple files
        # @param file_paths [Array<String>] Paths to files
        # @param component_type [Symbol] Type of component
        # @return [Array<Hash>] Array of validation results
        def self.validate_files(file_paths, component_type = :auto)
          file_paths.map { |path| validate_file(path, component_type) }
        end
      end
    end
  end
end