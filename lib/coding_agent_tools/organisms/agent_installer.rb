# frozen_string_literal: true

require 'pathname'
require_relative '../molecules/file_operation_executor'
require_relative '../molecules/metadata_injector'
require_relative '../molecules/statistics_collector'
require_relative '../models/file_operation'
require_relative '../models/command_metadata'
require_relative '../atoms/timestamp_generator'

module CodingAgentTools
  module Organisms
    # AgentInstaller handles installation of Claude agent files
    # This is an organism - it orchestrates molecules to install agents
    class AgentInstaller
      def initialize(
        file_executor: Molecules::FileOperationExecutor.new,
        metadata_injector: Molecules::MetadataInjector.new,
        stats_collector: Molecules::StatisticsCollector.new
      )
        @file_executor = file_executor
        @metadata_injector = metadata_injector
        @stats_collector = stats_collector
      end

      # Install agents from source to target
      # @param source_dir [Pathname] Source agents directory
      # @param target_dir [Pathname] Target agents directory
      # @param options [Hash] Installation options
      # @return [Hash] Installation result
      def install_agents(source_dir, target_dir, options = {})
        source_path = normalize_path(source_dir)
        target_path = normalize_path(target_dir)
        
        unless source_path.exist?
          return {
            success: true,
            message: "No agents directory found",
            stats: @stats_collector.stats
          }
        end

        puts "Copying agents..." if options[:verbose]
        
        # Find agent files
        agent_files = source_path.glob('*.md').sort
        
        if agent_files.empty?
          puts "  No agent files found" if options[:verbose]
          return {
            success: true,
            message: "No agent files to install",
            stats: @stats_collector.stats
          }
        end

        # Ensure target directory exists
        ensure_result = @file_executor.ensure_target_directory(
          Models::FileOperation.new(
            source: source_path,
            target: target_path / 'dummy',
            type: :create
          )
        )
        
        unless ensure_result[:success]
          @stats_collector.record_error("Failed to create agents directory: #{ensure_result[:error]}")
          return {
            success: false,
            error: ensure_result[:error],
            stats: @stats_collector.stats
          }
        end

        # Install each agent
        results = []
        agent_count = 0
        
        agent_files.each do |agent_file|
          operation = create_agent_operation(agent_file, target_path)
          result = install_single_agent(operation, options)
          results << result
          agent_count += 1 if result[:status] == :completed
        end

        puts "  ✓ Copied #{agent_count} agents" if agent_count > 0
        puts if options[:verbose]

        {
          success: @stats_collector.success?,
          installed_count: agent_count,
          total_files: agent_files.size,
          operations: results,
          stats: @stats_collector.stats
        }
      end

      private

      def normalize_path(path)
        path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
      end

      def create_agent_operation(source_file, target_dir)
        Models::FileOperation.new(
          source: source_file,
          target: target_dir / source_file.basename,
          type: :copy,
          metadata: { type: :agent }
        )
      end

      def install_single_agent(operation, options)
        # Check if target exists
        if @file_executor.would_overwrite?(operation) && !options[:force]
          print_skip_message(operation, options)
          @stats_collector.record_skipped(:agent)
          return {
            status: :skipped,
            operation: operation,
            message: "Already exists"
          }
        end

        # Add metadata
        enhanced_operation = add_agent_metadata(operation)
        
        # Execute operation
        result = @file_executor.execute(enhanced_operation, options)
        
        # Record statistics
        @stats_collector.record_operation(result, :agent)
        
        # Print result
        print_result(operation, result, options)
        
        result
      end

      def add_agent_metadata(operation)
        return operation unless operation.source.exist?
        
        content = operation.source.read
        
        # Create agent-specific metadata
        metadata = Models::CommandMetadata.new(
          last_modified: Atoms::TimestampGenerator.iso_timestamp,
          type: 'agent',
          source: 'dev-handbook'
        )
        
        # Inject metadata
        enhanced_content = @metadata_injector.inject(content, metadata)
        
        # Return operation with enhanced content
        operation.with_metadata(
          operation.metadata.merge(content: enhanced_content)
        )
      end

      def print_skip_message(operation, options)
        if options[:verbose]
          puts "  ✗ Skipped: #{operation.target_filename} (already exists)"
        end
      end

      def print_result(operation, result, options)
        return if options[:dry_run]
        
        case result[:status]
        when :completed
          puts "  ✓ Created: #{operation.target_filename}" if options[:verbose]
        when :failed
          puts "  ✗ Failed: #{operation.target_filename} - #{result[:error]}"
        end
      end
    end
  end
end