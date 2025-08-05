# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'yaml'
require_relative '../organisms/claude_commands_orchestrator'
require_relative '../models/installation_options'
require_relative '../models/installation_result'
require_relative '../molecules/project_root_finder'
require_relative '../molecules/metadata_injector'

module CodingAgentTools
  module Integrations
    # Installer for Claude Code commands from workflow instructions
    # This class now serves as a thin wrapper around the ATOM-structured orchestrator
    # maintaining backward compatibility while delegating to proper components
    class ClaudeCommandsInstaller
      attr_reader :project_root, :stats, :options

      def initialize(project_root = nil, options = {})
        @project_root_param = project_root
        @options_param = options
        
        # Build the orchestrator with all dependencies
        @orchestrator = build_orchestrator
        
        # Initialize backward-compatible attributes
        initialize_legacy_attributes(project_root, options)
      end

      def run
        # Delegate to orchestrator
        result = @orchestrator.run(@project_root_param, @options_param)
        
        # Update legacy attributes from result
        update_legacy_attributes(result)
        
        # Convert to legacy Result format
        convert_to_legacy_result(result)
      end

      # Result object for CLI integration
      Result = Struct.new(:success, :exit_code, :stats, keyword_init: true)

      # Legacy public methods for backward compatibility
      def validate_source!
        # This is now handled by the orchestrator
        # Keeping method for backward compatibility
      end

      def inject_metadata(content, metadata)
        # Delegate to metadata injector for backward compatibility
        injector = Molecules::MetadataInjector.new
        injector.inject(content, metadata)
      end

      private

      def build_orchestrator
        # Build complete dependency graph
        Organisms::ClaudeCommandsOrchestrator.new
      end

      def initialize_legacy_attributes(project_root, options)
        # Initialize attributes for backward compatibility
        finder = Molecules::ProjectRootFinder.new
        @project_root = Pathname.new(project_root || finder.find)
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

      def update_legacy_attributes(result)
        # Update stats from result
        if result.respond_to?(:stats) && result.stats
          stats_hash = result.stats.to_h
          @stats.merge!(stats_hash)
        end
      end

      def convert_to_legacy_result(result)
        # Convert from Models::InstallationResult to legacy Result
        Result.new(
          success: result.success?,
          exit_code: result.exit_code,
          stats: @stats
        )
      end

      # Legacy private methods kept for tests that might use them directly
      def validate_source!
        # Now handled by orchestrator through SourceDirectoryValidator
        # Keeping for backward compatibility
        source_base = options[:source] ? Pathname.new(options[:source]) : project_root / 'dev-handbook' / '.integrations' / 'claude'
        
        # Check for various structures
        commands_exist = (source_base / 'commands').exist?
        custom_exist = (source_base / 'commands' / '_custom').exist?
        generated_exist = (source_base / 'commands' / '_generated').exist?
        agents_exist = (source_base / 'agents').exist?
        
        # Check if flat structure has command files
        has_flat_commands = false
        if commands_exist
          has_flat_commands = (source_base / 'commands').glob('*.md').reject { |f| f.basename.to_s == 'README.md' }.any?
        end
        
        # Accept flat structure, subdirectory structure, or both
        if !commands_exist && !custom_exist && !generated_exist
          puts "Error: No command directories found at #{source_base}"
          exit 1
        elsif commands_exist && !has_flat_commands && !custom_exist && !generated_exist
          puts "Error: Commands directory exists but contains no command files"
          exit 1
        end
        
        unless agents_exist
          puts "Warning: No agents directory found at #{source_base / 'agents'}"
        end
      end

      # All the legacy private methods below are kept for backward compatibility
      # They are no longer used by the main run method, which delegates to the orchestrator
      # Some tests may still call these methods directly

      def create_backup
        # Legacy method - now handled by BackupCreator molecule
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
        # Legacy method - now handled by AgentInstaller organism
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
        # Legacy method - now handled by FileOperationExecutor molecule
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

      def ensure_directory_exists(dir)
        # Legacy method - now handled by DirectoryCreator atom
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
        # Legacy method - now handled by ProjectRootFinder molecule
        current = Pathname.pwd
        while current.parent != current
          return current if (current / '.claude' / 'commands').directory?
          current = current.parent
        end
        
        # Fallback to current directory if .claude/commands doesn't exist
        Pathname.pwd
      end

      def ensure_directories_exist
        # Legacy method - now handled by orchestrator
        commands_dir = project_root / '.claude' / 'commands'
        agents_dir = project_root / '.claude' / 'agents'
        
        ensure_directory_exists(commands_dir)
        ensure_directory_exists(agents_dir)
      end

      def copy_custom_commands
        # Legacy method - now handled by CommandInstaller organism
        source_base = options[:source] ? Pathname.new(options[:source]) : project_root / 'dev-handbook' / '.integrations' / 'claude'
        commands_dir = source_base / 'commands'
        custom_dir = source_base / 'commands' / '_custom'
        generated_dir = source_base / 'commands' / '_generated'
        target_dir = project_root / '.claude' / 'commands'
        
        # Check if we have a flat structure (new) or subdirectory structure (legacy)
        has_flat_structure = commands_dir.glob('*.md').reject { |f| f.basename.to_s == 'README.md' }.any?
        has_subdirs = custom_dir.exist? || generated_dir.exist?
        
        puts "Copying commands:"
        total_count = 0
        
        if has_flat_structure
          # Copy from flat structure
          commands_dir.glob('*.md').each do |file|
            next if file.basename.to_s == 'README.md'
            result = copy_file_with_metadata(file, target_dir / file.basename, 'command')
            total_count += 1 if result == :created
          end
          puts "  ✓ Copied #{total_count} commands from flat structure"
        elsif has_subdirs
          # Legacy: Copy from subdirectories
          custom_count = 0
          generated_count = 0
          
          # Copy custom commands
          if custom_dir.exist?
            custom_dir.glob('*.md').each do |file|
              result = copy_file_with_metadata(file, target_dir / file.basename, 'custom_command')
              custom_count += 1 if result == :created
            end
            stats[:custom_commands] = custom_count
          end

          # Copy generated commands  
          if generated_dir.exist?
            generated_dir.glob('*.md').each do |file|
              result = copy_file_with_metadata(file, target_dir / file.basename, 'generated_command')
              generated_count += 1 if result == :created
            end
            stats[:generated_commands] = generated_count
          end
          
          total_count = custom_count + generated_count
          puts "  ✓ Copied #{custom_count} custom commands" if custom_count > 0
          puts "  ✓ Copied #{generated_count} generated commands" if generated_count > 0
        end
        
        stats[:custom_commands] = total_count if has_flat_structure
        puts if total_count > 0
      end

      def copy_command_file(file)
        # Legacy method - now handled by FileOperationExecutor molecule
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
        # Legacy method - now handled by WorkflowCommandGenerator organism
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
        # Legacy method - now handled by WorkflowCommandGenerator organism
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
        # Legacy method - now handled by CommandTemplateRenderer molecule
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
        # Legacy method - now handled by CommandTemplateRenderer molecule
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

      def print_enhanced_summary
        # Legacy method - now handled by orchestrator
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