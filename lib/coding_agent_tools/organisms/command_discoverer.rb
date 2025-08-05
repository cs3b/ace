# frozen_string_literal: true

require 'pathname'
require_relative '../molecules/source_directory_validator'

module CodingAgentTools
  module Organisms
    # CommandDiscoverer finds and categorizes Claude commands from various sources
    # This is an organism - it orchestrates molecules to discover commands
    class CommandDiscoverer
      def initialize(source_validator: Molecules::SourceDirectoryValidator.new)
        @source_validator = source_validator
      end

      # Discover all available commands
      # @param source_base [String, Pathname] Base source directory
      # @return [Hash] Discovered commands by category
      def discover(source_base)
        validation = @source_validator.validate(source_base)
        
        unless validation[:valid]
          return {
            success: false,
            errors: validation[:errors],
            commands: {}
          }
        end

        base_path = validation[:base_path]
        structure_type = @source_validator.structure_type(validation)
        
        commands = {
          custom: [],
          generated: [],
          workflow: [],
          flat: []
        }

        # Discover based on structure type
        case structure_type
        when :flat
          discover_flat_commands(base_path, commands)
        when :subdirs
          discover_subdir_commands(base_path, commands)
        when :mixed
          discover_flat_commands(base_path, commands)
          discover_subdir_commands(base_path, commands)
        end

        # Discover workflow commands (always check)
        discover_workflow_commands(base_path, commands)

        {
          success: true,
          structure_type: structure_type,
          commands: commands,
          totals: calculate_totals(commands)
        }
      end

      # Discover agents
      # @param source_base [String, Pathname] Base source directory
      # @return [Array<Pathname>] List of agent files
      def discover_agents(source_base)
        base_path = normalize_path(source_base)
        agents_dir = base_path / 'agents'
        
        return [] unless agents_dir.exist? && agents_dir.directory?
        
        agents_dir.glob('*.md').sort
      end

      # Get command category for a file
      # @param file_path [Pathname] Command file path
      # @param source_structure [Symbol] Structure type
      # @return [Symbol] Command category
      def categorize_command(file_path, source_structure = :unknown)
        parent_dir = file_path.parent.basename.to_s
        
        case parent_dir
        when '_custom'
          :custom
        when '_generated'
          :generated
        when 'commands'
          source_structure == :flat ? :flat : :unknown
        else
          :unknown
        end
      end

      private

      def normalize_path(path)
        path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
      end

      def discover_flat_commands(base_path, commands)
        commands_dir = base_path / 'commands'
        return unless commands_dir.exist?

        command_files = @source_validator.find_command_files(commands_dir)
        commands[:flat] = command_files
      end

      def discover_subdir_commands(base_path, commands)
        commands_dir = base_path / 'commands'
        
        # Check custom commands
        custom_dir = commands_dir / '_custom'
        if custom_dir.exist?
          commands[:custom] = @source_validator.find_command_files(custom_dir)
        end

        # Check generated commands
        generated_dir = commands_dir / '_generated'
        if generated_dir.exist?
          commands[:generated] = @source_validator.find_command_files(generated_dir)
        end
      end

      def discover_workflow_commands(base_path, commands)
        # Look for workflow files in parent directories
        parent = base_path.parent
        workflows_dir = parent.parent / 'workflow-instructions'
        
        if workflows_dir.exist?
          workflow_files = workflows_dir.glob('*.wf.md').sort
          commands[:workflow] = workflow_files
        end
      end

      def calculate_totals(commands)
        {
          custom: commands[:custom].size,
          generated: commands[:generated].size,
          workflow: commands[:workflow].size,
          flat: commands[:flat].size,
          total: commands.values.flatten.size
        }
      end
    end
  end
end