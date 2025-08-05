# frozen_string_literal: true

require 'pathname'
require_relative '../atoms/path_sanitizer'

module CodingAgentTools
  module Molecules
    # SourceDirectoryValidator validates Claude command source directories
    # This is a molecule - it performs focused validation operations
    class SourceDirectoryValidator
      def initialize(path_sanitizer: Atoms::PathSanitizer)
        @path_sanitizer = path_sanitizer
      end

      # Validate source directory structure
      # @param source_base [String, Pathname] Base source directory
      # @return [Hash] Validation result with structure info
      def validate(source_base)
        base_path = normalize_path(source_base)

        result = {
          valid: false,
          base_path: base_path,
          commands_exist: false,
          custom_exist: false,
          generated_exist: false,
          agents_exist: false,
          has_flat_commands: false,
          has_subdirs: false,
          errors: [],
          warnings: []
        }

        # Check if base exists
        unless base_path.exist?
          result[:errors] << "Source directory does not exist: #{base_path}"
          return result
        end

        # Check directory structure
        check_commands_directory(base_path, result)
        check_agents_directory(base_path, result)

        # Determine validity
        determine_validity(result)

        result
      end

      # Check if path has valid command files
      # @param path [String, Pathname] Directory to check
      # @return [Array<Pathname>] List of command files
      def find_command_files(path)
        dir_path = normalize_path(path)
        return [] unless dir_path.exist? && dir_path.directory?

        # Find all .md files except README.md
        dir_path.glob('*.md').reject { |f| f.basename.to_s.downcase == 'readme.md' }
      end

      # Get source structure type
      # @param validation_result [Hash] Result from validate method
      # @return [Symbol] :flat, :subdirs, :mixed, or :none
      def structure_type(validation_result)
        if validation_result[:has_flat_commands] && validation_result[:has_subdirs]
          :mixed
        elsif validation_result[:has_flat_commands]
          :flat
        elsif validation_result[:has_subdirs]
          :subdirs
        else
          :none
        end
      end

      private

      def normalize_path(path)
        return path if path.is_a?(Pathname)
        Pathname.new(path.to_s)
      end

      def check_commands_directory(base_path, result)
        commands_dir = base_path / 'commands'
        custom_dir = commands_dir / '_custom'
        generated_dir = commands_dir / '_generated'

        # Check main commands directory
        if commands_dir.exist?
          result[:commands_exist] = true

          # Check for flat structure (command files directly in commands/)
          command_files = find_command_files(commands_dir)
          result[:has_flat_commands] = command_files.any?
        end

        # Check subdirectories
        result[:custom_exist] = custom_dir.exist? && custom_dir.directory?
        result[:generated_exist] = generated_dir.exist? && generated_dir.directory?
        result[:has_subdirs] = result[:custom_exist] || result[:generated_exist]
      end

      def check_agents_directory(base_path, result)
        agents_dir = base_path / 'agents'
        result[:agents_exist] = agents_dir.exist? && agents_dir.directory?

        unless result[:agents_exist]
          result[:warnings] << "No agents directory found at #{agents_dir}"
        end
      end

      def determine_validity(result)
        # Valid if we have either flat commands, subdirectories, or both
        has_commands = result[:has_flat_commands] || result[:has_subdirs]

        if !result[:commands_exist] && !result[:custom_exist] && !result[:generated_exist]
          result[:errors] << 'No command directories found'
          result[:valid] = false
        elsif result[:commands_exist] && !has_commands
          result[:errors] << 'Commands directory exists but contains no command files'
          result[:valid] = false
        else
          result[:valid] = has_commands
        end
      end
    end
  end
end
