# frozen_string_literal: true

require 'pathname'
require 'time'
require_relative '../../atoms/claude/command_existence_checker'
require_relative '../../atoms/claude/workflow_scanner'

module CodingAgentTools
  module Molecules
    module Claude
      # Builds a unified inventory of Claude commands from multiple sources
      # This is a behavior-oriented helper that centralizes command discovery logic
      class CommandInventoryBuilder
        attr_reader :project_root

        def initialize(project_root)
          @project_root = Pathname.new(project_root)
        end

        # Build a complete inventory of commands
        # @param options [Hash] Options for building inventory
        # @option options [String] :type Filter by type (custom, generated, missing, all)
        # @return [Hash] Inventory with :commands array and summary counts
        def build(options = {})
          # Get commands from all sources
          custom_commands = scan_custom_commands
          generated_commands = scan_generated_commands
          installed_names = scan_installed_command_names

          # Build unified command list
          all_commands = []

          # Add custom commands
          custom_commands.each do |cmd|
            all_commands << cmd.merge(
              installed: installed_names.include?(cmd[:name]),
              valid: true
            )
          end

          # Add generated commands
          generated_commands.each do |cmd|
            all_commands << cmd.merge(
              installed: installed_names.include?(cmd[:name]),
              valid: true
            )
          end

          # Find and add missing commands
          known_names = (custom_commands + generated_commands).map { |c| c[:name] }
          missing_commands = find_missing_workflows(known_names)
          
          missing_commands.each do |name|
            all_commands << {
              name: name,
              type: 'missing',
              installed: false,
              valid: false
            }
          end

          # Filter by type if requested
          if options[:type] && options[:type] != 'all'
            all_commands = filter_by_type(all_commands, options[:type])
          end

          {
            commands: all_commands.sort_by { |cmd| cmd[:name] },
            installed_count: all_commands.count { |cmd| cmd[:installed] },
            missing_count: all_commands.count { |cmd| !cmd[:valid] },
            custom_count: all_commands.count { |cmd| cmd[:type] == 'custom' },
            generated_count: all_commands.count { |cmd| cmd[:type] == 'generated' }
          }
        end

        # Get command search paths
        # @return [Array<Pathname>] Array of paths to search for commands
        def command_search_paths
          [
            @project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom',
            @project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated',
            @project_root / '.claude' / 'commands' / '_custom',
            @project_root / '.claude' / 'commands' / '_generated',
            @project_root / '.claude' / 'commands' # Flat structure
          ]
        end

        private

        def scan_custom_commands
          dir = @project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
          scan_directory(dir, 'custom')
        end

        def scan_generated_commands
          dir = @project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
          scan_directory(dir, 'generated')
        end

        def scan_directory(dir, type)
          return [] unless dir.exist?

          Dir.glob(File.join(dir, '*.md')).map do |path|
            build_command_info(path, type)
          end.sort_by { |cmd| cmd[:name] }
        end

        def build_command_info(path, type)
          pathname = Pathname.new(path)
          stat = File.stat(path)

          {
            name: pathname.basename('.md').to_s,
            path: pathname.relative_path_from(@project_root).to_s,
            type: type,
            size: stat.size,
            modified: stat.mtime,
            modified_iso: stat.mtime.iso8601
          }
        end

        def scan_installed_command_names
          names = []
          installed_paths = [
            @project_root / '.claude' / 'commands' / '_custom',
            @project_root / '.claude' / 'commands' / '_generated',
            @project_root / '.claude' / 'commands'
          ]

          installed_paths.each do |path|
            next unless path.exist?

            names += Dir.glob(File.join(path, '*.md'))
                        .reject { |f| File.basename(f).downcase == 'readme.md' }
                        .map { |f| File.basename(f, '.md') }
          end

          names.uniq
        end

        def find_missing_workflows(known_command_names)
          workflow_dir = @project_root / 'dev-handbook' / 'workflow-instructions'
          
          # Use WorkflowScanner atom to get all workflows
          all_workflows = Atoms::Claude::WorkflowScanner.scan(workflow_dir)
          
          # Find workflows without commands
          missing = all_workflows - known_command_names
          missing.sort
        end

        def filter_by_type(commands, type)
          case type
          when 'custom'
            commands.select { |cmd| cmd[:type] == 'custom' }
          when 'generated'
            commands.select { |cmd| cmd[:type] == 'generated' }
          when 'missing'
            commands.select { |cmd| cmd[:type] == 'missing' }
          else
            commands
          end
        end
      end
    end
  end
end