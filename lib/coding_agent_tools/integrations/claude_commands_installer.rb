# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'

module CodingAgentTools
  module Integrations
    # Installer for Claude Code commands from workflow instructions
    class ClaudeCommandsInstaller
      attr_reader :project_root, :stats, :options

      def initialize(project_root = nil, options = {})
        @project_root = Pathname.new(project_root || find_project_root)
        @stats = { created: 0, skipped: 0, updated: 0, errors: [] }
        @options = { dry_run: false, verbose: false }.merge(options)
      end

      def run
        puts "Installing Claude Code commands#{options[:dry_run] ? ' (DRY RUN)' : ''}..."
        puts "Project root: #{project_root}" if options[:verbose]
        puts

        # Ensure directories exist
        ensure_directories_exist

        # Copy custom multi-task commands first
        copy_custom_commands

        # Scan workflows and create commands
        workflow_files = scan_workflows
        create_commands_from_workflows(workflow_files)

        # Update commands.json
        update_commands_json

        # Print summary
        print_summary
        
        # Return result object instead of exiting
        Result.new(success: stats[:errors].empty?, exit_code: stats[:errors].empty? ? 0 : 1, stats: stats)
      rescue StandardError => e
        puts "Error: #{e.message}"
        puts e.backtrace if ENV['DEBUG'] || options[:verbose]
        stats[:errors] << e.message
        Result.new(success: false, exit_code: 1, stats: stats)
      end

      # Result object for CLI integration
      Result = Struct.new(:success, :exit_code, :stats, keyword_init: true)

      private

      def find_project_root
        # Look for .claude/commands directory to identify project root
        current = Pathname.pwd
        while current.parent != current
          return current if (current / '.claude' / 'commands').directory?
          current = current.parent
        end
        
        # Fallback to current directory if .claude/commands doesn't exist
        Pathname.pwd
      end

      def ensure_directories_exist
        commands_dir = project_root / '.claude' / 'commands'
        unless commands_dir.exist?
          if options[:dry_run]
            puts "Would create directory: #{commands_dir}" if options[:verbose]
          else
            FileUtils.mkdir_p(commands_dir)
            puts "Created directory: #{commands_dir}" if options[:verbose]
          end
        end
      end

      def copy_custom_commands
        # Look for commands in both _custom and _generated directories
        custom_dir = project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        generated_dir = project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        
        # Copy custom commands
        if custom_dir.exist?
          puts "Copying custom multi-task commands..."
          custom_dir.glob('*.md').each do |file|
            copy_command_file(file)
          end
        end

        # Copy generated commands
        if generated_dir.exist?
          puts "Copying generated workflow commands..."
          generated_dir.glob('*.md').each do |file|
            copy_command_file(file)
          end
        end
        
        puts if custom_dir.exist? || generated_dir.exist?
      end

      def copy_command_file(file)
        target = project_root / '.claude' / 'commands' / file.basename
        if target.exist?
          puts "  ✗ Skipped: #{file.basename} (already exists)"
          stats[:skipped] += 1
        else
          if options[:dry_run]
            puts "  ✓ Would create: #{file.basename}"
          else
            FileUtils.cp(file, target)
            puts "  ✓ Created: #{file.basename}"
          end
          stats[:created] += 1
        end
      end

      def scan_workflows
        workflows_dir = project_root / 'dev-handbook' / 'workflow-instructions'
        unless workflows_dir.exist?
          puts "Warning: Workflow instructions directory not found at #{workflows_dir}"
          return []
        end

        workflows = workflows_dir.glob('*.wf.md').sort
        puts "Found #{workflows.length} workflow files"
        workflows
      end

      def create_commands_from_workflows(workflow_files)
        puts "Creating command files..."
        
        workflow_files.each do |workflow_file|
          command_name = workflow_file.basename.to_s.sub('.wf.md', '')
          command_file = project_root / '.claude' / 'commands' / "#{command_name}.md"
          
          if command_file.exist?
            puts "  ✗ Skipped: #{command_name}.md (already exists)"
            stats[:skipped] += 1
          else
            create_command_file(workflow_file, command_file)
            puts "  ✓ Created: #{command_name}.md"
            stats[:created] += 1
          end
        end
        puts
      end

      def create_command_file(workflow_file, command_file)
        workflow_name = workflow_file.basename.to_s.sub('.wf.md', '')
        
        # Check for custom template
        custom_content = get_custom_template(workflow_name)
        
        content = if custom_content
          custom_content
        else
          # Use default template
          <<~CONTENT
            read whole file and follow @dev-handbook/workflow-instructions/#{workflow_file.basename}

            read and run @.claude/commands/commit.md
          CONTENT
        end
        
        if options[:dry_run]
          puts "    Would write: #{command_file.relative_path_from(project_root)}" if options[:verbose]
        else
          command_file.write(content)
        end
      end

      def get_custom_template(workflow_name)
        # Check if there's a custom template defined
        # For now, we'll handle the special case for commit and load-project-context
        case workflow_name
        when 'commit'
          <<~CONTENT
            Read the entire file: @dev-handbook/workflow-instructions/commit.wf.md

            Follow the instructions exactly, including creating the git commit with the specific format shown.
          CONTENT
        when 'load-project-context'
          <<~CONTENT
            Read the entire file: @dev-handbook/workflow-instructions/load-project-context.wf.md

            Load all the context documents listed in the workflow.
          CONTENT
        else
          nil
        end
      end

      def update_commands_json
        json_file = project_root / '.claude' / 'commands' / 'commands.json'
        
        # Create backup if file exists
        if json_file.exist? && !options[:dry_run]
          backup_file = project_root / '.claude' / 'commands' / 'commands.json.backup'
          FileUtils.cp(json_file, backup_file)
          puts "Created backup: commands.json.backup" if options[:verbose]
        end

        # Load existing JSON or create new
        commands = json_file.exist? ? JSON.parse(json_file.read) : {}
        
        # Get all command files
        command_files = (project_root / '.claude' / 'commands').glob('*.md')
        new_commands = 0
        
        command_files.each do |file|
          next if file.basename.to_s == 'README.md'
          
          command_name = "/#{file.basename.to_s.sub('.md', '')}"
          unless commands.key?(command_name)
            commands[command_name] = {}
            new_commands += 1
          end
        end
        
        # Sort commands alphabetically
        sorted_commands = commands.sort.to_h
        
        # Write updated JSON
        if options[:dry_run]
          if new_commands > 0
            puts "✓ Would update: commands.json (#{new_commands} new entries)"
            stats[:updated] += 1
          else
            puts "✓ commands.json is up to date"
          end
        else
          json_file.write(JSON.pretty_generate(sorted_commands) + "\n")
          
          if new_commands > 0
            puts "✓ Updated: commands.json (#{new_commands} new entries added)"
            stats[:updated] += 1
          else
            puts "✓ commands.json is up to date"
          end
        end
        puts
      end

      def print_summary
        total = stats[:created] + stats[:skipped]
        
        puts "="*50
        puts "Installation complete:"
        puts "  #{stats[:created]} created"
        puts "  #{stats[:skipped]} skipped"
        puts "  #{stats[:updated]} files updated"
        
        if stats[:errors].any?
          puts
          puts "Errors encountered:"
          stats[:errors].each { |error| puts "  - #{error}" }
        end
        
        puts "="*50
      end
    end
  end
end