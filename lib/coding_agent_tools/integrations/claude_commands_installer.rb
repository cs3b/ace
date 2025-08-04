# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'

module CodingAgentTools
  module Integrations
    # Installer for Claude Code commands from workflow instructions
    class ClaudeCommandsInstaller
      attr_reader :project_root, :stats

      def initialize(project_root = nil)
        @project_root = Pathname.new(project_root || find_project_root)
        @stats = { created: 0, skipped: 0, updated: 0, errors: [] }
      end

      def run
        puts "Installing Claude Code commands..."
        puts "Project root: #{project_root}"
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
      rescue StandardError => e
        puts "Error: #{e.message}"
        puts e.backtrace if ENV['DEBUG']
        exit 1
      end

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
        FileUtils.mkdir_p(commands_dir) unless commands_dir.exist?
      end

      def copy_custom_commands
        custom_commands_dir = project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands'
        return unless custom_commands_dir.exist?

        puts "Copying custom multi-task commands..."
        custom_commands_dir.glob('*.md').each do |file|
          target = project_root / '.claude' / 'commands' / file.basename
          if target.exist?
            puts "  ✗ Skipped: #{file.basename} (already exists)"
            stats[:skipped] += 1
          else
            FileUtils.cp(file, target)
            puts "  ✓ Created: #{file.basename}"
            stats[:created] += 1
          end
        end
        puts
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
        
        if custom_content
          command_file.write(custom_content)
        else
          # Use default template
          content = <<~CONTENT
            read whole file and follow @dev-handbook/workflow-instructions/#{workflow_file.basename}

            read and run @.claude/commands/commit.md
          CONTENT
          
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
        if json_file.exist?
          backup_file = project_root / '.claude' / 'commands' / 'commands.json.backup'
          FileUtils.cp(json_file, backup_file)
          puts "Created backup: commands.json.backup"
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
        json_file.write(JSON.pretty_generate(sorted_commands) + "\n")
        
        if new_commands > 0
          puts "✓ Updated: commands.json (#{new_commands} new entries added)"
          stats[:updated] += 1
        else
          puts "✓ commands.json is up to date"
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