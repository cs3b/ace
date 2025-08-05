# frozen_string_literal: true

require 'json'
require 'pathname'
require 'time'
require_relative '../atoms/project_root_detector'

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
        
        # Also scan .claude/commands/ for installed commands
        installed_commands = scan_installed_commands
        
        # Find workflows without corresponding commands
        missing_commands = find_missing_workflows(installed_commands)
        
        {
          custom: custom_commands,
          generated: generated_commands,
          missing: missing_commands,
          installed: installed_commands
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

      def scan_installed_commands
        dir = project_root / '.claude' / 'commands'
        return [] unless dir.exist?
        
        Dir.glob(File.join(dir, '*.md')).reject { |f| File.basename(f) == 'README.md' }.map do |path|
          build_command_info(path, 'installed')
        end.sort_by { |cmd| cmd[:name] }
      end

      def find_missing_workflows(installed_commands)
        workflows_dir = project_root / 'dev-handbook' / 'workflow-instructions'
        return [] unless workflows_dir.exist?
        
        # Get workflow names
        workflow_names = Dir.glob(File.join(workflows_dir, '*.wf.md')).map do |path|
          File.basename(path, '.wf.md')
        end
        
        # Get installed command names
        installed_names = installed_commands.map { |cmd| cmd[:name] }
        
        # Find workflows without commands
        missing = workflow_names - installed_names
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
        case type
        when 'custom'
          { custom: inventory[:custom] }
        when 'generated'
          { generated: inventory[:generated] }
        when 'missing'
          { missing: inventory[:missing] }
        else
          inventory
        end
      end

      def output_json(inventory, _options)
        output = {}
        
        # Add custom commands with metadata
        if inventory[:custom]
          output['custom'] = inventory[:custom].map do |cmd|
            {
              'name' => cmd[:name],
              'path' => cmd[:path],
              'modified' => cmd[:modified_iso],
              'size' => cmd[:size]
            }
          end
        end
        
        # Add generated commands with metadata
        if inventory[:generated]
          output['generated'] = inventory[:generated].map do |cmd|
            {
              'name' => cmd[:name],
              'path' => cmd[:path],
              'modified' => cmd[:modified_iso],
              'size' => cmd[:size]
            }
          end
        end
        
        # Add missing commands (just names)
        output['missing'] = inventory[:missing] if inventory[:missing]
        
        puts JSON.pretty_generate(output)
      end

      def output_text(inventory, options)
        puts "Claude Commands Overview"
        puts "========================"
        puts

        # Count totals
        custom_count = inventory[:custom]&.length || 0
        generated_count = inventory[:generated]&.length || 0
        missing_count = inventory[:missing]&.length || 0
        total_available = custom_count + generated_count

        # Display custom commands
        if inventory[:custom] && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'custom')
          if options[:verbose]
            puts "Custom Commands (#{custom_count}):"
            inventory[:custom].each do |cmd|
              puts "  #{colorize('✓', :green)} #{cmd[:name]}"
              puts "    Path: #{cmd[:path]}"
              puts "    Modified: #{cmd[:modified].strftime('%Y-%m-%d %H:%M:%S')}"
              puts "    Size: #{format_size(cmd[:size])}"
            end
          else
            puts "Custom Commands (#{custom_count}):"
            inventory[:custom].each do |cmd|
              puts "  #{colorize('✓', :green)} #{cmd[:name]}"
            end
          end
          puts
        end

        # Display generated commands
        if inventory[:generated] && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'generated')
          if options[:verbose]
            puts "Generated Commands (#{generated_count}):"
            inventory[:generated].each do |cmd|
              puts "  #{colorize('✓', :green)} #{cmd[:name]}"
              puts "    Path: #{cmd[:path]}"
              puts "    Modified: #{cmd[:modified].strftime('%Y-%m-%d %H:%M:%S')}"
              puts "    Size: #{format_size(cmd[:size])}"
            end
          else
            puts "Generated Commands (#{generated_count}):"
            inventory[:generated].each do |cmd|
              puts "  #{colorize('✓', :green)} #{cmd[:name]}"
            end
          end
          puts
        end

        # Display missing commands
        if inventory[:missing]&.any? && (options[:type].nil? || options[:type] == 'all' || options[:type] == 'missing')
          puts "Missing Commands (#{missing_count}):"
          inventory[:missing].each do |name|
            puts "  #{colorize('✗', :red)} #{name}"
          end
          puts
        end

        # Display summary
        if options[:type].nil? || options[:type] == 'all'
          puts "Summary: #{total_available} commands available, #{missing_count} missing"
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