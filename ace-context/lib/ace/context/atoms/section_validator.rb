# frozen_string_literal: true

module Ace
  module Context
    module Atoms
      # Validates section definitions and ensures section integrity
      class SectionValidator
        class SectionValidationError < StandardError; end

        # Valid section content types
        VALID_CONTENT_TYPES = %w[files commands diffs content].freeze

        # Required section fields
        REQUIRED_FIELDS = %w[title content_type].freeze

        def initialize
          @errors = []
        end

        # Validates section definitions from configuration
        # @param sections [Hash] section definitions hash
        # @return [Boolean] true if valid, false otherwise
        def validate_sections(sections)
          @errors.clear()
          return true if sections.nil? || sections.empty?

          validate_section_names(sections)
          validate_required_fields(sections)
          validate_content_types(sections)
          validate_priorities(sections)
          validate_section_content(sections)

          @errors.empty?
        end

        # Returns validation errors
        # @return [Array<String>] list of validation errors
        def errors
          @errors
        end

        # Validates a single section
        # @param name [String] section name
        # @param section [Hash] section definition
        # @return [Boolean] true if valid, false otherwise
        def validate_section(name, section)
          @errors.clear()
          return true if section.nil? || section.empty?

          validate_section_name(name)
          validate_required_fields_for_section(name, section)
          validate_content_type_for_section(name, section)
          validate_priority_for_section(name, section)
          validate_content_for_section(name, section)

          @errors.empty?
        end

        private

        # Validates section names are unique and valid
        def validate_section_names(sections)
          section_names = sections.keys
          duplicates = section_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys

          duplicates.each do |duplicate|
            @errors << "Duplicate section name: #{duplicate}"
          end

          section_names.each do |name|
            validate_section_name(name)
          end
        end

        # Validates a single section name
        def validate_section_name(name)
          if name.nil? || name.to_s.strip.empty?
            @errors << "Section name cannot be empty"
          elsif !name.to_s.match?(/\A[a-zA-Z0-9_-]+\z/)
            @errors << "Section name '#{name}' contains invalid characters. Use letters, numbers, underscores, and hyphens only."
          end
        end

        # Validates required fields for all sections
        def validate_required_fields(sections)
          sections.each do |name, section|
            validate_required_fields_for_section(name, section)
          end
        end

        # Validates required fields for a single section
        def validate_required_fields_for_section(name, section)
          REQUIRED_FIELDS.each do |field|
            unless section.key?(field) && !section[field].nil? && !section[field].to_s.strip.empty?
              @errors << "Section '#{name}' missing required field: #{field}"
            end
          end
        end

        # Validates content types for all sections
        def validate_content_types(sections)
          sections.each do |name, section|
            validate_content_type_for_section(name, section)
          end
        end

        # Validates content type for a single section
        def validate_content_type_for_section(name, section)
          content_type = section[:content_type] || section['content_type']

          unless VALID_CONTENT_TYPES.include?(content_type)
            @errors << "Section '#{name}' has invalid content_type: #{content_type}. Must be one of: #{VALID_CONTENT_TYPES.join(', ')}"
          end
        end

        # Validates priorities for all sections
        def validate_priorities(sections)
          sections.each do |name, section|
            validate_priority_for_section(name, section)
          end
        end

        # Validates priority for a single section
        def validate_priority_for_section(name, section)
          priority = section[:priority] || section['priority']

          if priority && !priority.is_a?(Integer)
            @errors << "Section '#{name}' priority must be an integer, got: #{priority.class}"
          elsif priority && (priority < 1 || priority > 1000)
            @errors << "Section '#{name}' priority must be between 1 and 1000, got: #{priority}"
          end
        end

        # Validates content for all sections
        def validate_section_content(sections)
          sections.each do |name, section|
            validate_content_for_section(name, section)
          end
        end

        # Validates content for a single section
        def validate_content_for_section(name, section)
          content_type = section[:content_type] || section['content_type']

          case content_type
          when 'files'
            validate_files_content(name, section)
          when 'commands'
            validate_commands_content(name, section)
          when 'diffs'
            validate_diffs_content(name, section)
          when 'content'
            validate_inline_content(name, section)
          end
        end

        # Validates files content for a section
        def validate_files_content(name, section)
          files = section[:files] || section['files']

          if files.nil? || files.empty?
            @errors << "Section '#{name}' with content_type 'files' must specify files array"
          elsif !files.is_a?(Array)
            @errors << "Section '#{name}' files must be an array"
          else
            files.each_with_index do |file, index|
              validate_file_item(name, file, index)
            end
          end
        end

        # Validates a single file item
        def validate_file_item(section_name, file, index)
          if file.is_a?(Hash)
            path = file[:path] || file['path']
            if path.nil? || path.to_s.strip.empty?
              @errors << "Section '#{section_name}' file at index #{index} missing path"
            end
          elsif file.is_a?(String)
            if file.strip.empty?
              @errors << "Section '#{section_name}' file at index #{index} cannot be empty string"
            end
          else
            @errors << "Section '#{section_name}' file at index #{index} must be string or hash"
          end
        end

        # Validates commands content for a section
        def validate_commands_content(name, section)
          commands = section[:commands] || section['commands']

          if commands.nil? || commands.empty?
            @errors << "Section '#{name}' with content_type 'commands' must specify commands array"
          elsif !commands.is_a?(Array)
            @errors << "Section '#{name}' commands must be an array"
          else
            commands.each_with_index do |command, index|
              if command.to_s.strip.empty?
                @errors << "Section '#{name}' command at index #{index} cannot be empty"
              end
            end
          end
        end

        # Validates diffs content for a section
        def validate_diffs_content(name, section)
          ranges = section[:ranges] || section['ranges']

          if ranges.nil? || ranges.empty?
            @errors << "Section '#{name}' with content_type 'diffs' must specify ranges array"
          elsif !ranges.is_a?(Array)
            @errors << "Section '#{name}' ranges must be an array"
          else
            ranges.each_with_index do |range, index|
              if range.to_s.strip.empty?
                @errors << "Section '#{name}' range at index #{index} cannot be empty"
              end
            end
          end
        end

        # Validates inline content for a section
        def validate_inline_content(name, section)
          content = section[:content] || section['content']

          if content.nil? || content.to_s.strip.empty?
            @errors << "Section '#{name}' with content_type 'content' must specify content"
          end
        end
      end
    end
  end
end