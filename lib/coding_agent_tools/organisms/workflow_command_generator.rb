# frozen_string_literal: true

require 'pathname'
require_relative '../molecules/command_template_renderer'
require_relative '../molecules/file_operation_executor'
require_relative '../molecules/statistics_collector'
require_relative '../models/file_operation'

module CodingAgentTools
  module Organisms
    # WorkflowCommandGenerator creates Claude commands from workflow files
    # This is an organism - it orchestrates molecules to generate commands
    class WorkflowCommandGenerator
      def initialize(
        template_renderer: Molecules::CommandTemplateRenderer.new,
        file_executor: Molecules::FileOperationExecutor.new,
        stats_collector: Molecules::StatisticsCollector.new
      )
        @template_renderer = template_renderer
        @file_executor = file_executor
        @stats_collector = stats_collector
      end

      # Generate commands from workflow files
      # @param workflow_files [Array<Pathname>] List of workflow files
      # @param target_dir [Pathname] Target commands directory
      # @param options [Hash] Generation options
      # @return [Hash] Generation result
      def generate_commands(workflow_files, target_dir, options = {})
        puts 'Creating command files...' if options[:verbose]

        operations = prepare_operations(workflow_files, target_dir)
        results = []

        operations.each do |operation|
          result = generate_single_command(operation, options)
          results << result
          print_result(operation, result, options)
        end

        puts if options[:verbose]

        {
          success: @stats_collector.success?,
          generated_count: count_generated(results),
          total_workflows: workflow_files.size,
          operations: results,
          stats: @stats_collector.stats
        }
      end

      # Generate a single command from a workflow
      # @param operation [Models::FileOperation] Generation operation
      # @param options [Hash] Generation options
      # @return [Hash] Operation result
      def generate_single_command(operation, options)
        # Check if target exists
        if @file_executor.would_overwrite?(operation) && !options[:force]
          @stats_collector.record_skipped(:workflow_command)
          return {
            status: :skipped,
            operation: operation,
            message: 'Already exists'
          }
        end

        # Generate command content
        workflow_name = extract_workflow_name(operation.source)
        content = @template_renderer.render(workflow_name, operation.source.basename.to_s)

        # Create operation with content
        create_operation = operation.with_metadata(
          operation.metadata.merge(content: content)
        )

        # Execute operation
        result = @file_executor.execute(create_operation, options)

        # Record statistics
        @stats_collector.record_operation(result, :workflow_command)

        result
      end

      # Scan for workflow files in a directory
      # @param project_root [Pathname] Project root directory
      # @return [Array<Pathname>] Found workflow files
      def scan_workflows(project_root)
        workflows_dir = project_root / 'dev-handbook' / 'workflow-instructions'

        unless workflows_dir.exist?
          puts "Warning: Workflow instructions directory not found at #{workflows_dir}"
          return []
        end

        workflows = workflows_dir.glob('*.wf.md').sort
        puts "Found #{workflows.length} workflow files"
        workflows
      end

      private

      def prepare_operations(workflow_files, target_dir)
        workflow_files.map do |workflow_file|
          command_name = workflow_file.basename.to_s.sub('.wf.md', '')
          target_file = target_dir / "#{command_name}.md"

          Models::FileOperation.new(
            source: workflow_file,
            target: target_file,
            type: :create,
            metadata: {
              source_type: 'workflow',
              workflow_name: command_name
            }
          )
        end
      end

      def extract_workflow_name(workflow_path)
        workflow_path.basename.to_s.sub('.wf.md', '')
      end

      def print_result(operation, result, options)
        command_name = operation.metadata[:workflow_name]

        case result[:status]
        when :completed
          puts "  ✓ Created: #{command_name}.md"
        when :skipped
          puts "  ✗ Skipped: #{command_name}.md (already exists)"
        when :failed
          puts "  ✗ Failed: #{command_name}.md - #{result[:error]}"
        end
      end

      def count_generated(results)
        results.count { |r| r[:status] == :completed }
      end
    end
  end
end
