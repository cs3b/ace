# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'
require 'yaml'

module CodingAgentTools
  module Integrations
    # Installer for Claude Code commands from workflow instructions
    class ClaudeCommandsInstaller
      attr_reader :project_root, :stats, :options

      def initialize(project_root = nil, options = {})
        @project_root = Pathname.new(project_root || find_project_root)
        @stats = { 
          created: 0, 
          skipped: 0, 
          updated: 0, 
          errors: [],
          custom_commands: 0,
          generated_commands: 0,
          workflow_commands: 0,
          agents: 0
        }
        @options = { 
          dry_run: false, 
          verbose: false,
          backup: false,
          force: false,
          source: nil
        }.merge(options)
      end

      def run
        puts "Installing Claude commands#{options[:dry_run] ? ' (DRY RUN)' : ''}..."
        puts "Project root: #{project_root}" if options[:verbose]
        puts

        # Validate source directories
        validate_source!
        
        # Create backup if requested
        create_backup if options[:backup]

        # Ensure directories exist
        ensure_directories_exist

        # Copy commands from new structure (_custom and _generated)
        copy_custom_commands
        
        # Copy agents
        copy_agents

        # Scan workflows and create generated commands (existing functionality)
        workflow_files = scan_workflows
        create_commands_from_workflows(workflow_files)

        # Update commands.json
        update_commands_json

        # Print summary
        print_enhanced_summary
        
        # Return result object
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

      def validate_source!
        source_base = options[:source] ? Pathname.new(options[:source]) : project_root / 'dev-handbook' / '.integrations' / 'claude'
        
        # Check for new structure with subdirectories
        commands_exist = (source_base / 'commands').exist?
        custom_exist = (source_base / 'commands' / '_custom').exist?
        generated_exist = (source_base / 'commands' / '_generated').exist?
        agents_exist = (source_base / 'agents').exist?
        
        # For now, accept current flat structure or new subdirectory structure
        if !commands_exist && !custom_exist && !generated_exist
          puts "Error: No command directories found at #{source_base}"
          exit 1
        end
        
        unless agents_exist
          puts "Warning: No agents directory found at #{source_base / 'agents'}"
        end
      end

      def create_backup
        target = project_root / '.claude'
        return unless target.exist? && options[:backup]
        
        timestamp = Time.now.strftime("%Y%m%d-%H%M")
        backup_path = project_root / ".claude.backup.#{timestamp}"
        
        if options[:dry_run]
          puts "Would create backup at: #{backup_path}" if options[:verbose]
        else
          FileUtils.cp_r(target, backup_path)
          puts "✓ Backed up existing .claude/ to #{backup_path}/"
        end
      end

      def copy_agents
        source_base = options[:source] ? Pathname.new(options[:source]) : project_root / 'dev-handbook' / '.integrations' / 'claude'
        agents_dir = source_base / 'agents'
        target_dir = project_root / '.claude' / 'agents'
        
        return unless agents_dir.exist?
        
        ensure_directory_exists(target_dir)
        
        puts "Copying agents..."
        agent_count = 0
        agents_dir.glob('*.md').each do |file|
          result = copy_file_with_metadata(file, target_dir / file.basename, 'agent')
          agent_count += 1 if result == :created
        end
        puts "  ✓ Copied #{agent_count} agents"
        puts
      end

      def copy_file_with_metadata(source, target, type = 'command')
        if target.exist? && !options[:force]
          puts "  ✗ Skipped: #{target.basename} (already exists)"
          stats[:skipped] += 1
          return :skipped
        end

        content = source.read
        
        # Add or update metadata
        content = inject_metadata(content, {
          'last_modified' => Time.now.strftime('%Y-%m-%d %H:%M:%S')
        })
        
        if options[:dry_run]
          puts "  ✓ Would create: #{target.basename} (with metadata)"
        else
          target.write(content)
          puts "  ✓ Created: #{target.basename}"
        end
        stats[:created] += 1
        stats[:agents] += 1 if type == 'agent'
        return :created
      end

      def inject_metadata(content, metadata)
        # Handle YAML front-matter injection/update
        if content =~ /\A---\n(.*?)\n---\n/m
          # Update existing front-matter
          begin
            yaml = YAML.safe_load($1) || {}
            yaml.merge!(metadata)
            new_frontmatter = YAML.dump(yaml).sub(/^---\n/, '')
            content.sub(/\A---\n.*?\n---\n/m, "---\n#{new_frontmatter}---\n")
          rescue => e
            # If YAML parsing fails, just add the metadata as new fields
            frontmatter_lines = $1.split("\n")
            metadata.each do |key, value|
              frontmatter_lines << "#{key}: #{value}"
            end
            "---\n#{frontmatter_lines.join("\n")}\n---\n" + content.sub(/\A---\n.*?\n---\n/m, '')
          end
        else
          # Add new front-matter
          "---\n#{YAML.dump(metadata).sub(/^---\n/, '')}---\n\n#{content}"
        end
      end

      def ensure_directory_exists(dir)
        unless dir.exist?
          if options[:dry_run]
            puts "Would create directory: #{dir}" if options[:verbose]
          else
            FileUtils.mkdir_p(dir)
            puts "Created directory: #{dir}" if options[:verbose]
          end
        end
      end

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
        agents_dir = project_root / '.claude' / 'agents'
        
        ensure_directory_exists(commands_dir)
        ensure_directory_exists(agents_dir)
      end

      def copy_custom_commands
        source_base = options[:source] ? Pathname.new(options[:source]) : project_root / 'dev-handbook' / '.integrations' / 'claude'
        custom_dir = source_base / 'commands' / '_custom'
        generated_dir = source_base / 'commands' / '_generated'
        target_dir = project_root / '.claude' / 'commands'
        
        # Copy custom commands
        if custom_dir.exist?
          puts "Copying commands:"
          custom_count = 0
          custom_dir.glob('*.md').each do |file|
            result = copy_file_with_metadata(file, target_dir / file.basename, 'custom_command')
            custom_count += 1 if result == :created
          end
          stats[:custom_commands] = custom_count
          puts "  ✓ Copied #{custom_count} custom commands"
        end

        # Copy generated commands  
        if generated_dir.exist?
          generated_count = 0
          generated_dir.glob('*.md').each do |file|
            result = copy_file_with_metadata(file, target_dir / file.basename, 'generated_command')
            generated_count += 1 if result == :created
          end
          stats[:generated_commands] = generated_count
          puts "  ✓ Copied #{generated_count} generated commands"
        end
        
        puts if custom_dir.exist? || generated_dir.exist?
      end

      def copy_command_file(file)
        target = project_root / '.claude' / 'commands' / file.basename
        if target.exist? && !options[:force]
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
          stats[:workflow_commands] += 1
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
            stats[:workflow_commands] += 1
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

      def print_enhanced_summary
        puts "="*50
        puts "Installation complete:"
        puts "  Location: #{project_root / '.claude'}/"
        puts "  Commands: #{stats[:custom_commands] + stats[:generated_commands] + stats[:workflow_commands]}"
        puts "  Agents: #{stats[:agents]}"
        
        unless options[:dry_run]
          puts
          puts "Run 'claude code' to use the new commands"
        end
        
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