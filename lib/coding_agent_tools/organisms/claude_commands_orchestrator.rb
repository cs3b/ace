# frozen_string_literal: true

require 'pathname'
require_relative '../models/installation_options'
require_relative '../models/installation_stats'
require_relative '../models/installation_result'
require_relative '../molecules/project_root_finder'
require_relative '../molecules/source_directory_validator'
require_relative '../molecules/backup_creator'
require_relative '../molecules/statistics_collector'
require_relative '../atoms/code/directory_creator'
require_relative 'command_discoverer'
require_relative 'command_installer'
require_relative 'agent_installer'
require_relative 'workflow_command_generator'

module CodingAgentTools
  module Organisms
    # ClaudeCommandsOrchestrator coordinates the entire Claude command installation process
    # This is an organism - it orchestrates all other components
    class ClaudeCommandsOrchestrator
      def initialize(
        project_root_finder: Molecules::ProjectRootFinder.new,
        source_validator: Molecules::SourceDirectoryValidator.new,
        backup_creator: Molecules::BackupCreator.new,
        command_discoverer: CommandDiscoverer.new,
        command_installer: CommandInstaller.new,
        agent_installer: AgentInstaller.new,
        workflow_generator: WorkflowCommandGenerator.new,
        stats_collector: Molecules::StatisticsCollector.new,
        directory_creator: Atoms::Code::DirectoryCreator.new
      )
        @project_root_finder = project_root_finder
        @source_validator = source_validator
        @backup_creator = backup_creator
        @command_discoverer = command_discoverer
        @command_installer = command_installer
        @agent_installer = agent_installer
        @workflow_generator = workflow_generator
        @stats_collector = stats_collector
        @directory_creator = directory_creator
      end

      # Run the complete installation process
      # @param project_root [String, Pathname, nil] Project root directory
      # @param options [Models::InstallationOptions, Hash] Installation options
      # @return [Models::InstallationResult] Installation result
      def run(project_root = nil, options = {})
        # Convert options to model if needed
        @options = case options
                   when Models::InstallationOptions
                     options
                   when Hash
                     Models::InstallationOptions.from_hash(options)
                   else
                     Models::InstallationOptions.new
                   end

        # Find project root
        @project_root = find_and_validate_project_root(project_root)
        
        puts "Installing Claude commands#{@options.dry_run? ? ' (DRY RUN)' : ''}..."
        puts "Project root: #{@project_root}" if @options.verbose?
        puts

        # Execute installation phases
        validate_source_directories
        create_backup_if_requested
        ensure_target_directories_exist
        install_all_components
        
        # Print summary
        print_summary
        
        # Return result
        create_result
      rescue StandardError => e
        handle_error(e)
      end

      private

      def find_and_validate_project_root(project_root)
        root = project_root ? Pathname.new(project_root) : @project_root_finder.find
        unless root.exist?
          raise "Project root does not exist: #{root}"
        end
        root
      end

      def validate_source_directories
        source_base = determine_source_base
        validation = @source_validator.validate(source_base)
        
        unless validation[:valid]
          puts "Error: #{validation[:errors].first}"
          exit 1
        end
        
        validation[:warnings].each { |warning| puts "Warning: #{warning}" }
        @source_validation = validation
      end

      def determine_source_base
        if @options.custom_source?
          Pathname.new(@options.source)
        else
          @project_root / 'dev-handbook' / '.integrations' / 'claude'
        end
      end

      def create_backup_if_requested
        return unless @options.backup?
        
        target = @project_root / '.claude'
        result = @backup_creator.create_backup(target, dry_run: @options.dry_run?)
        
        if result[:success]
          puts "✓ #{result[:message] || result[:path]}"
        else
          puts "Warning: #{result[:error]}"
        end
      end

      def ensure_target_directories_exist
        commands_dir = @project_root / '.claude' / 'commands'
        agents_dir = @project_root / '.claude' / 'agents'
        
        [commands_dir, agents_dir].each do |dir|
          result = @directory_creator.create_if_not_exists(dir.to_s)
          if result[:created] && @options.verbose?
            puts "Created directory: #{dir}"
          end
        end
      end

      def install_all_components
        source_base = determine_source_base
        target_base = @project_root / '.claude'
        
        # Discover all components
        discovery = @command_discoverer.discover(source_base)
        
        # Install commands based on structure
        install_discovered_commands(discovery[:commands], target_base / 'commands')
        
        # Install agents
        install_agents(source_base / 'agents', target_base / 'agents')
        
        # Generate workflow commands
        generate_workflow_commands(target_base / 'commands')
      end

      def install_discovered_commands(commands, target_dir)
        # Install flat commands
        if commands[:flat].any?
          result = @command_installer.install_commands(
            commands[:flat],
            target_dir,
            @options.to_h
          )
          update_stats_from_result(result, :custom_commands)
          puts "  ✓ Copied #{result[:installed_count] || 0} commands from flat structure" if result[:installed_count]
        end
        
        # Install custom commands
        if commands[:custom].any?
          result = @command_installer.install_commands(
            commands[:custom],
            target_dir,
            @options.to_h
          )
          update_stats_from_result(result, :custom_commands)
          puts "  ✓ Copied #{result[:installed_count] || 0} custom commands" if result[:installed_count]
        end
        
        # Install generated commands
        if commands[:generated].any?
          result = @command_installer.install_commands(
            commands[:generated],
            target_dir,
            @options.to_h
          )
          update_stats_from_result(result, :generated_commands)
          puts "  ✓ Copied #{result[:installed_count] || 0} generated commands" if result[:installed_count]
        end
        
        puts if commands.values.any?(&:any?)
      end

      def install_agents(source_dir, target_dir)
        result = @agent_installer.install_agents(source_dir, target_dir, @options.to_h)
        update_stats_from_result(result, :agents)
      end

      def generate_workflow_commands(target_dir)
        workflow_files = @workflow_generator.scan_workflows(@project_root)
        return if workflow_files.empty?
        
        result = @workflow_generator.generate_commands(
          workflow_files,
          target_dir,
          @options.to_h
        )
        update_stats_from_result(result, :workflow_commands)
      end

      def update_stats_from_result(result, category = nil)
        return unless result[:stats]
        
        other_stats = result[:stats]
        @stats_collector.merge!(
          Molecules::StatisticsCollector.new(initial_stats: other_stats)
        )
      end

      def print_summary
        stats = @stats_collector.stats
        
        puts "="*50
        puts "Installation complete:"
        puts "  Location: #{@project_root / '.claude'}/"
        puts "  Commands: #{stats.total_commands}"
        puts "  Agents: #{stats.agents}"
        
        unless @options.dry_run?
          puts
          puts "Run 'claude code' to use the new commands"
        end
        
        if stats.errors?
          puts
          puts "Errors encountered:"
          stats.errors.each { |error| puts "  - #{error}" }
        end
        
        puts "="*50
      end

      def create_result
        stats = @stats_collector.stats
        if stats.errors?
          Models::InstallationResult.failure(stats)
        else
          Models::InstallationResult.success(stats)
        end
      end

      def handle_error(error)
        puts "Error: #{error.message}"
        puts error.backtrace if ENV['DEBUG'] || @options&.verbose?
        @stats_collector.record_error(error.message)
        Models::InstallationResult.failure(@stats_collector.stats)
      end
    end
  end
end