# frozen_string_literal: true

require "yaml"
require "ace/support/items"
require_relative "../atoms/retro_validation_rules"
require_relative "../atoms/retro_id_formatter"

module Ace
  module Retro
    module Molecules
      # Validates retro spec file frontmatter for correctness and completeness.
      # Returns an array of issue hashes with :type, :message, and :location keys.
      class RetroFrontmatterValidator
        # Validate a single retro spec file
        # @param file_path [String] Path to the .retro.md file
        # @param special_folder [String, nil] Special folder the retro is in
        # @return [Array<Hash>] List of issues found
        def self.validate(file_path, special_folder: nil)
          issues = []

          unless File.exist?(file_path)
            issues << { type: :error, message: "File does not exist", location: file_path }
            return issues
          end

          content = File.read(file_path)

          validate_delimiters(content, file_path, issues)
          return issues if issues.any? { |i| i[:type] == :error }

          frontmatter = parse_frontmatter(content, file_path, issues)
          return issues unless frontmatter

          validate_required_fields(frontmatter, file_path, issues)
          validate_field_values(frontmatter, file_path, issues)
          validate_recommended_fields(frontmatter, file_path, issues)
          validate_scope_consistency(frontmatter, special_folder, file_path, issues)

          issues
        end

        class << self
          private

          def validate_delimiters(content, file_path, issues)
            lines = content.lines

            unless lines.first&.strip == "---"
              issues << { type: :error, message: "Missing opening '---' delimiter", location: file_path }
              return
            end

            has_closing = lines[1..].any? { |line| line.strip == "---" }
            unless has_closing
              issues << { type: :error, message: "Missing closing '---' delimiter", location: file_path }
            end
          end

          def parse_frontmatter(content, file_path, issues)
            frontmatter, _body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

            if frontmatter.nil? || !frontmatter.is_a?(Hash)
              issues << { type: :error, message: "Failed to parse YAML frontmatter", location: file_path }
              return nil
            end

            frontmatter
          rescue Psych::SyntaxError => e
            issues << { type: :error, message: "YAML syntax error: #{e.message}", location: file_path }
            nil
          end

          def validate_required_fields(frontmatter, file_path, issues)
            missing = Atoms::RetroValidationRules.missing_required_fields(frontmatter)

            missing.each do |field|
              severity = (field == "title") ? :warning : :error
              issues << { type: severity, message: "Missing required field: #{field}", location: file_path }
            end
          end

          def validate_field_values(frontmatter, file_path, issues)
            if frontmatter["id"] && !Atoms::RetroValidationRules.valid_id?(frontmatter["id"].to_s)
              issues << { type: :error, message: "Invalid retro ID format: '#{frontmatter["id"]}'", location: file_path }
            end

            if frontmatter["status"] && !Atoms::RetroValidationRules.valid_status?(frontmatter["status"])
              issues << { type: :error, message: "Invalid status value: '#{frontmatter["status"]}'", location: file_path }
            end

            if frontmatter.key?("tags") && !frontmatter["tags"].is_a?(Array)
              issues << { type: :warning, message: "Field 'tags' is not an array", location: file_path }
            end
          end

          def validate_recommended_fields(frontmatter, file_path, issues)
            missing = Atoms::RetroValidationRules.missing_recommended_fields(frontmatter)

            missing.each do |field|
              issues << { type: :warning, message: "Missing recommended field: #{field}", location: file_path }
            end
          end

          def validate_scope_consistency(frontmatter, special_folder, file_path, issues)
            return unless frontmatter["status"]

            scope_issues = Atoms::RetroValidationRules.scope_consistent?(
              frontmatter["status"],
              special_folder
            )

            scope_issues.each do |issue|
              issues << issue.merge(location: file_path)
            end
          end
        end
      end
    end
  end
end
