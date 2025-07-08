# frozen_string_literal: true

require "pathname"
require "yaml"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for validating task metadata in markdown files
      # Extracted from dev-taskflow/.../lint-task-metadata
      class TaskMetadataValidator
        # Metadata Validation Rules
        VALID_ID_REGEX = /^v.\d+\.\d+\.\d+\+task\.\d+$/
        REQUIRED_FIELDS = ["id", "status", "priority"]
        VALID_STATUSES = ["pending", "in-progress", "done", "blocked", "icebox", "on-hold"]
        VALID_PRIORITIES = ["low", "medium", "high", "critical"]
        ESTIMATE_REGEX = /^\d+(\.\d+)?(h|d|w|sp|pt|wk|mo)$/i

        attr_reader :task_dirs

        def initialize(options = {})
          @task_dirs = options[:task_dirs] || default_task_dirs
        end

        def validate
          errors = []
          findings = []

          task_dirs.each do |dir|
            next unless Dir.exist?(dir)

            Dir.glob(File.join(dir, "**", "*.md")).each do |file|
              validate_task_file(file, errors, findings)
            end
          end

          {
            success: errors.empty?,
            errors: errors,
            findings: findings
          }
        end

        private

        def default_task_dirs
          [
            "dev-taskflow/current",
            "dev-taskflow/backlog"
          ]
        end

        def validate_task_file(file_path, errors, findings)
          content = File.read(file_path)
          frontmatter, body = parse_task_file_content(content, file_path, errors)

          return unless frontmatter

          validate_frontmatter(frontmatter, file_path, errors)
          validate_h1_title(body, file_path, errors) if body
        end

        def parse_task_file_content(content, file_path, errors)
          parts = content.split(/^---\s*$/m, 3)

          unless parts.length > 2 && (parts[0].nil? || parts[0].strip.empty?)
            errors << "#{file_path}: Malformed frontmatter"
            return [nil, nil]
          end

          frontmatter_text = parts[1]
          body_text = parts[2] || ""

          begin
            frontmatter = YAML.safe_load(frontmatter_text)
            frontmatter = {} if frontmatter.nil? || frontmatter == false

            unless frontmatter.is_a?(Hash)
              errors << "#{file_path}: Frontmatter is not a Hash"
              return [nil, body_text]
            end
          rescue Psych::SyntaxError => e
            errors << "#{file_path}: Invalid YAML - #{e.message}"
            return [nil, body_text]
          end

          [frontmatter, body_text]
        end

        def validate_frontmatter(fm, file_path, errors)
          # Check required fields
          REQUIRED_FIELDS.each do |field|
            unless fm.key?(field)
              errors << "#{file_path}: Missing required field '#{field}'"
            end
          end

          # Validate ID format
          if fm.key?("id")
            id_val = fm["id"]
            if id_val.is_a?(String)
              unless id_val.match?(VALID_ID_REGEX)
                errors << "#{file_path}: Invalid ID format '#{id_val}'"
              end
            elsif !(id_val.is_a?(Integer) && file_path.include?("backlog"))
              errors << "#{file_path}: ID must be a string"
            end
          end

          # Validate status
          if fm.key?("status")
            status_val = fm["status"]
            if status_val.is_a?(String)
              unless VALID_STATUSES.include?(status_val.downcase)
                errors << "#{file_path}: Invalid status '#{status_val}'"
              end
            else
              errors << "#{file_path}: Status must be a string"
            end
          end

          # Validate priority
          if fm.key?("priority")
            priority_val = fm["priority"]
            if priority_val.is_a?(String)
              unless VALID_PRIORITIES.include?(priority_val.downcase)
                errors << "#{file_path}: Invalid priority '#{priority_val}'"
              end
            else
              errors << "#{file_path}: Priority must be a string"
            end
          end

          # Validate estimate format
          if fm.key?("estimate")
            estimate_val = fm["estimate"]
            if estimate_val.is_a?(String)
              unless estimate_val.match?(ESTIMATE_REGEX)
                errors << "#{file_path}: Invalid estimate format '#{estimate_val}'"
              end
            end
          end

          # Validate dependencies
          if fm.key?("dependencies") && !fm["dependencies"].nil?
            unless fm["dependencies"].is_a?(Array)
              errors << "#{file_path}: Dependencies must be an array"
            end
          end
        end

        def validate_h1_title(body, file_path, errors)
          lines = body.lines
          h1_match = lines.find { |line| line.strip.start_with?("# ") }

          unless h1_match
            errors << "#{file_path}: Missing H1 title in body"
          end
        end
      end
    end
  end
end
