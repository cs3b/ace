# frozen_string_literal: true

require 'json'
require 'pathname'
require 'time'
require_relative '../atoms/project_root_detector'
require_relative '../atoms/table_renderer'

module CodingAgentTools
  module Organisms
    # Lists and categorizes Claude commands from various sources
    class ClaudeCommandLister
      attr_reader :project_root

      def initialize(project_root = nil)
        @project_root = Pathname.new(project_root || Atoms::ProjectRootDetector.find_project_root)
      end

      def list(options = {})
        inventory = build_inventory

        # Filter by type if specified
        if options[:type] && options[:type] != 'all'
          inventory = filter_inventory(inventory, options[:type])
        end

        case options[:format]
        when 'json'
          output_json(inventory, options)
        else
          output_text(inventory, options)
        end
      end

      private

      def build_inventory
        # Scan commands from source directories
        custom_commands = scan_custom_commands
        generated_commands = scan_generated_commands

        # Get list of installed command names
        installed_names = scan_installed_command_names

        # Build unified command list with installation status
        all_commands = []

        # Add custom commands
        custom_commands.each do |cmd|
          all_commands << cmd.merge(
            installed: installed_names.include?(cmd[:name]),
            valid: true  # Custom commands in dev-handbook are always valid
          )
        end

        # Add generated commands
        generated_commands.each do |cmd|
          all_commands << cmd.merge(
            installed: installed_names.include?(cmd[:name]),
            valid: true  # Generated commands in dev-handbook are always valid
          )
        end

        # Find workflows without corresponding commands
        missing_commands = find_missing_workflows(custom_commands + generated_commands)

        # Add missing commands
        missing_commands.each do |name|
          all_commands << {
            name: name,
            type: 'missing',
            installed: false,
            valid: false
          }
        end

        {
          commands: all_commands.sort_by { |cmd| cmd[:name] },
          installed_count: all_commands.count { |cmd| cmd[:installed] },
          missing_count: all_commands.count { |cmd| !cmd[:valid] }
        }
      end

      def scan_custom_commands
        dir = project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        return [] unless dir.exist?

        Dir.glob(File.join(dir, '*.md')).map do |path|
          build_command_info(path, 'custom')
        end.sort_by { |cmd| cmd[:name] }
      end

      def scan_generated_commands
        dir = project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        return [] unless dir.exist?

        Dir.glob(File.join(dir, '*.md')).map do |path|
          build_command_info(path, 'generated')
        end.sort_by { |cmd| cmd[:name] }
      end

      def scan_installed_command_names
        dir = project_root / '.claude' / 'commands'
        return [] unless dir.exist?

        # Check both subdirectories and root directory
        custom_dir = dir / '_custom'
        generated_dir = dir / '_generated'

        names = []

        # Scan custom commands
        if custom_dir.exist?
          names += Dir.glob(File.join(custom_dir, '*.md'))
            .map { |path| File.basename(path, '.md') }
        end

        # Scan generated commands
        if generated_dir.exist?
          names += Dir.glob(File.join(generated_dir, '*.md'))
            .map { |path| File.basename(path, '.md') }
        end

        # Also check root directory for flat structure
        names += Dir.glob(File.join(dir, '*.md'))
          .reject { |f| File.basename(f) == 'README.md' }
          .map { |path| File.basename(path, '.md') }

        names.uniq
      end

      def find_missing_workflows(known_commands)
        workflows_dir = project_root / 'dev-handbook' / 'workflow-instructions'
        return [] unless workflows_dir.exist?

        # Get workflow names
        workflow_names = Dir.glob(File.join(workflows_dir, '*.wf.md')).map do |path|
          File.basename(path, '.wf.md')
        end

        # Get known command names (custom + generated)
        known_names = known_commands.map { |cmd| cmd[:name] }

        # Find workflows without commands
        missing = workflow_names - known_names
        missing.sort
      end

      def build_command_info(path, type)
        pathname = Pathname.new(path)
        stat = File.stat(path)

        {
          name: pathname.basename('.md').to_s,
          path: pathname.relative_path_from(project_root).to_s,
          type: type,
          size: stat.size,
          modified: stat.mtime,
          modified_iso: stat.mtime.iso8601
        }
      end

      def filter_inventory(inventory, type)
        filtered_commands = case type
        when 'custom'
          inventory[:commands].select { |cmd| cmd[:type] == 'custom' }
        when 'generated'
          inventory[:commands].select { |cmd| cmd[:type] == 'generated' }
        when 'missing'
          inventory[:commands].select { |cmd| cmd[:type] == 'missing' }
        else
          inventory[:commands]
        end

        {
          commands: filtered_commands,
          installed_count: filtered_commands.count { |cmd| cmd[:installed] },
          missing_count: filtered_commands.count { |cmd| !cmd[:valid] }
        }
      end

      def output_json(inventory, _options)
        output = {
          'commands' => inventory[:commands].map do |cmd|
            {
              'name' => cmd[:name],
              'installed' => cmd[:installed],
              'type' => cmd[:type],
              'valid' => cmd[:valid]
            }.tap do |h|
              # Add optional fields if present
              h['path'] = cmd[:path] if cmd[:path]
              h['modified'] = cmd[:modified_iso] if cmd[:modified_iso]
              h['size'] = cmd[:size] if cmd[:size]
            end
          end,
          'summary' => {
            'installed' => inventory[:installed_count],
            'missing' => inventory[:missing_count],
            'total' => inventory[:commands].length
          }
        }

        puts JSON.pretty_generate(output)
      end

      def output_text(inventory, options)
        puts 'Claude Commands Overview'
        puts '========================'
        puts

        if options[:verbose]
          # Use old verbose format
          output_verbose(inventory, options)
        else
          # Use new table format
          output_table(inventory, options)
        end
      end

      def output_table(inventory, options)
        # Define columns
        columns = [
          { name: 'Installed', width: 10, align: :center },
          { name: 'Type', width: 10, align: :left },
          { name: 'Valid', width: 8, align: :center },
          { name: 'Command Name', align: :left }
        ]

        # Create table renderer
        table = Atoms::TableRenderer.new(columns)

        # Add rows
        inventory[:commands].each do |cmd|
          installed_mark = cmd[:installed] ? colorize('✓', :green) : colorize('✗', :red)
          valid_mark = cmd[:valid] ? colorize('✓', :green) : colorize('✗', :red)

          table.add_row([
            installed_mark,
            cmd[:type],
            valid_mark,
            cmd[:name]
          ])
        end

        # Render table
        puts table.render
        puts

        # Display summary
        total = inventory[:commands].length
        installed = inventory[:installed_count]
        missing = inventory[:missing_count]

        puts "Summary: #{installed} commands installed, #{missing} missing (#{total} total)"
      end

      def output_verbose(inventory, options)
        # Group commands by type for verbose output
        by_type = inventory[:commands].group_by { |cmd| cmd[:type] }

        # Display custom commands
        if by_type['custom'] && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'custom')
          puts "Custom Commands (#{by_type["custom"].length}):"
          by_type['custom'].each do |cmd|
            status = cmd[:installed] ? colorize('✓', :green) : colorize('✗', :red)
            puts "  #{status} #{cmd[:name]}"
            if cmd[:path]
              puts "    Path: #{cmd[:path]}"
              puts "    Modified: #{cmd[:modified].strftime("%Y-%m-%d %H:%M:%S")}"
              puts "    Size: #{format_size(cmd[:size])}"
            end
          end
          puts
        end

        # Display generated commands
        if by_type['generated'] && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'generated')
          puts "Generated Commands (#{by_type["generated"].length}):"
          by_type['generated'].each do |cmd|
            status = cmd[:installed] ? colorize('✓', :green) : colorize('✗', :red)
            puts "  #{status} #{cmd[:name]}"
            if cmd[:path]
              puts "    Path: #{cmd[:path]}"
              puts "    Modified: #{cmd[:modified].strftime("%Y-%m-%d %H:%M:%S")}"
              puts "    Size: #{format_size(cmd[:size])}"
            end
          end
          puts
        end

        # Display missing commands
        if by_type['missing'] && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'missing')
          puts "Missing Commands (#{by_type["missing"].length}):"
          by_type['missing'].each do |cmd|
            puts "  #{colorize("✗", :red)} #{cmd[:name]}"
          end
          puts
        end

        # Display summary
        if options[:type].nil? || options[:type] == 'all'
          total = inventory[:commands].length
          installed = inventory[:installed_count]
          missing = inventory[:missing_count]
          puts "Summary: #{installed} commands installed, #{missing} missing (#{total} total)"
        end
      end

      def colorize(text, color)
        case color
        when :red
          "\e[31m#{text}\e[0m"
        when :green
          "\e[32m#{text}\e[0m"
        when :yellow
          "\e[33m#{text}\e[0m"
        when :blue
          "\e[34m#{text}\e[0m"
        else
          text
        end
      end

      def format_size(bytes)
        if bytes < 1024
          "#{bytes} bytes"
        elsif bytes < 1024 * 1024
          "#{(bytes / 1024.0).round(1)} KB"
        else
          "#{(bytes / (1024.0 * 1024)).round(1)} MB"
        end
      end
    end
  end
end
