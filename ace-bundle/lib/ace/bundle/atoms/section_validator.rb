# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Validates section definitions and ensures section integrity
      class SectionValidator
        SectionValidationError = Ace::Bundle::SectionValidationError

        # Required section fields (none - all fields are optional)
        REQUIRED_FIELDS = [].freeze

        def initialize
          @errors = []
        end

        # Validates section definitions from configuration
        # @param sections [Hash] section definitions hash
        # @return [Boolean] true if valid, false otherwise
        def validate_sections(sections)
          @errors.clear
          return true if sections.nil? || sections.empty?

          validate_section_names(sections)
          validate_required_fields(sections)
          validate_section_content(sections)

          @errors.empty?
        end

        # Returns validation errors
        # @return [Array<String>] list of validation errors
        attr_reader :errors

        # Validates a single section
        # @param name [String] section name
        # @param section [Hash] section definition
        # @return [Boolean] true if valid, false otherwise
        def validate_section(name, section)
          @errors.clear
          return true if section.nil? || section.empty?

          validate_section_name(name)
          validate_required_fields_for_section(name, section)
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

        # Validates content for all sections
        def validate_section_content(sections)
          sections.each do |name, section|
            validate_content_for_section(name, section)
          end
        end

        # Validates content for a single section
        def validate_content_for_section(name, section)
          # Validate all content types that are present
          validate_files_content(name, section)
          validate_commands_content(name, section)
          validate_diffs_content(name, section)
          validate_presets_content(name, section)
          validate_inline_content(name, section)
        end

        # Validates files content for a section
        def validate_files_content(name, section)
          files = section[:files] || section["files"]

          # Only validate if files are present
          return if files.nil? || files.empty?

          unless files.is_a?(Array)
            @errors << "Section '#{name}' files must be an array"
            return
          end

          files.each_with_index do |file, index|
            validate_file_item(name, file, index)
          end
        end

        # Validates a single file item
        def validate_file_item(section_name, file, index)
          if file.is_a?(Hash)
            path = file[:path] || file["path"]
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
          commands = section[:commands] || section["commands"]

          # Only validate if commands are present
          return if commands.nil? || commands.empty?

          unless commands.is_a?(Array)
            @errors << "Section '#{name}' commands must be an array"
            return
          end

          commands.each_with_index do |command, index|
            if command.to_s.strip.empty?
              @errors << "Section '#{name}' command at index #{index} cannot be empty"
            end
          end
        end

        # Validates diffs content for a section
        def validate_diffs_content(name, section)
          ranges = section[:ranges] || section["ranges"]

          # Only validate if ranges are present
          return if ranges.nil? || ranges.empty?

          unless ranges.is_a?(Array)
            @errors << "Section '#{name}' ranges must be an array"
            return
          end

          ranges.each_with_index do |range, index|
            if range.to_s.strip.empty?
              @errors << "Section '#{name}' range at index #{index} cannot be empty"
            end
          end
        end

        # Validates presets content for a section
        def validate_presets_content(name, section)
          presets = section[:presets] || section["presets"]

          # Only validate if presets are present
          return if presets.nil? || presets.empty?

          unless presets.is_a?(Array)
            @errors << "Section '#{name}' presets must be an array"
            return
          end

          presets.each_with_index do |preset, index|
            if preset.is_a?(String)
              if preset.strip.empty?
                @errors << "Section '#{name}' preset at index #{index} cannot be empty string"
              end
            else
              @errors << "Section '#{name}' preset at index #{index} must be a string"
            end
          end
        end

        # Validates inline content for a section
        def validate_inline_content(name, section)
          content = section[:content] || section["content"]

          # Only validate if content is present
          nil if content.nil? || content.to_s.strip.empty?

          # Content validation (if needed in future)
          # Currently just ensures content is present if specified
        end
      end
    end
  end
end
