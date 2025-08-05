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
    # CommandInstaller handles installation of Claude commands with metadata
    # This is an organism - it orchestrates molecules to install commands
    class CommandInstaller
      def initialize(
        file_executor: Molecules::FileOperationExecutor.new,
        metadata_injector: Molecules::MetadataInjector.new,
        stats_collector: Molecules::StatisticsCollector.new
      )
        @file_executor = file_executor
        @metadata_injector = metadata_injector
        @stats_collector = stats_collector
      end

      # Install commands from a source directory
      # @param source_files [Array<Pathname>] List of command files to install
      # @param target_dir [Pathname] Target directory for installation
      # @param options [Hash] Installation options
      # @return [Hash] Installation result
      def install_commands(source_files, target_dir, options = {})
        puts 'Copying commands:' if options[:verbose]

        operations = prepare_operations(source_files, target_dir, options)
        results = []

        operations.each do |operation|
          result = install_single_command(operation, options)
          results << result

          # Print progress
          print_operation_result(operation, result, options)
        end

        {
          success: @stats_collector.success?,
          operations: results,
          stats: @stats_collector.stats,
          summary: @stats_collector.summary_message
        }
      end

      # Install a single command file
      # @param operation [Models::FileOperation] File operation
      # @param options [Hash] Installation options
      # @return [Hash] Operation result
      def install_single_command(operation, options = {})
        # Skip if target exists and not forcing
        if @file_executor.would_overwrite?(operation) && !options[:force]
          @stats_collector.record_skipped(:command)
          return {
            status: :skipped,
            operation: operation,
            message: 'Already exists'
          }
        end

        # Add metadata to content
        enhanced_operation = add_metadata_to_operation(operation)

        # Execute the operation
        result = @file_executor.execute(enhanced_operation, options)

        # Record statistics
        @stats_collector.record_operation(result, :command)

        result
      end

      private

      def prepare_operations(source_files, target_dir, options)
        source_files.map do |source_file|
          target_file = target_dir / source_file.basename

          Models::FileOperation.new(
            source: source_file,
            target: target_file,
            type: :copy,
            metadata: {
              source_type: detect_source_type(source_file)
            }
          )
        end
      end

      def add_metadata_to_operation(operation)
        # Read source content
        return operation unless operation.source.exist?

        content = operation.source.read

        # Create metadata
        metadata = Models::CommandMetadata.new(
          last_modified: Atoms::TimestampGenerator.iso_timestamp,
          source: operation.metadata[:source_type]
        )

        # Inject metadata into content
        enhanced_content = @metadata_injector.inject(content, metadata)

        # Return new operation with enhanced content
        operation.with_metadata(
          operation.metadata.merge(content: enhanced_content)
        )
      end

      def detect_source_type(file_path)
        parent_dir = file_path.parent.basename.to_s

        case parent_dir
        when '_custom'
          'custom'
        when '_generated'
          'generated'
        when 'commands'
          'flat'
        else
          'unknown'
        end
      end

      def print_operation_result(operation, result, options)
        return if options[:dry_run]

        case result[:status]
        when :completed
          puts "  ✓ Created: #{operation.target_filename}"
        when :skipped
          puts "  ✗ Skipped: #{operation.target_filename} (#{result[:message]})" if options[:verbose]
        when :failed
          puts "  ✗ Failed: #{operation.target_filename} - #{result[:error]}"
        end
      end
    end
  end
end
