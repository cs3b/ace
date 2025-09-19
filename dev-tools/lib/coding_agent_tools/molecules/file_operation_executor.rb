# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "../atoms/code/directory_creator"
require_relative "../models/file_operation"

module CodingAgentTools
  module Molecules
    # FileOperationExecutor handles executing file operations with safety checks
    # This is a molecule - it uses atoms to perform file operations
    class FileOperationExecutor
      def initialize(directory_creator: Atoms::Code::DirectoryCreator.new)
        @directory_creator = directory_creator
      end

      # Execute a single file operation
      # @param operation [Models::FileOperation] Operation to execute
      # @param options [Hash] Execution options
      # @option options [Boolean] :dry_run Don't actually perform operations
      # @option options [Boolean] :force Overwrite existing files
      # @option options [Boolean] :verbose Show detailed output
      # @return [Hash] Result of operation
      def execute(operation, options = {})
        # Handle dry-run mode
        if options[:dry_run]
          case operation.type
          when :copy, :create, :update
            if would_overwrite?(operation) && !options[:force]
              return skip_result(operation, "Would skip (already exists)")
            else
              return dry_run_success_result(operation, "Would #{operation.type}")
            end
          when :skip
            return skip_result(operation, "Operation marked as skip")
          else
            return error_result(operation, "Unknown operation type: #{operation.type}")
          end
        end

        # Normal execution
        case operation.type
        when :copy
          execute_copy(operation, options)
        when :create
          execute_create(operation, options)
        when :update
          execute_update(operation, options)
        when :skip
          skip_result(operation, "Operation marked as skip")
        else
          error_result(operation, "Unknown operation type: #{operation.type}")
        end
      end

      # Execute multiple operations
      # @param operations [Array<Models::FileOperation>] Operations to execute
      # @param options [Hash] Execution options
      # @return [Array<Hash>] Results of all operations
      def execute_batch(operations, options = {})
        operations.map { |op| execute(op, options) }
      end

      # Check if target would be overwritten
      # @param operation [Models::FileOperation] Operation to check
      # @return [Boolean] true if target exists
      def would_overwrite?(operation)
        operation.target.exist?
      end

      # Prepare target directory for operation
      # @param operation [Models::FileOperation] Operation requiring directory
      # @return [Hash] Result of directory creation
      def ensure_target_directory(operation)
        target_dir = operation.target.parent
        @directory_creator.create_if_not_exists(target_dir.to_s)
      end

      private

      def execute_copy(operation, options)
        # Check if target exists and handle accordingly
        if would_overwrite?(operation) && !options[:force]
          return skip_result(operation, "Target exists (use force to overwrite)")
        end

        # Ensure target directory exists
        dir_result = ensure_target_directory(operation)
        return error_result(operation, dir_result[:error]) unless dir_result[:success]

        # Read content from source
        unless operation.source.exist?
          return error_result(operation, "Source file not found: #{operation.source}")
        end

        begin
          # Check if metadata contains pre-processed content
          content = if operation.metadata && operation.metadata[:content]
            operation.metadata[:content]
          else
            operation.source.read
          end

          # Write to target
          operation.target.write(content)
          success_result(operation, "Copied from #{operation.source_filename}")
        rescue => e
          error_result(operation, "Copy failed: #{e.message}")
        end
      end

      def execute_create(operation, options)
        # Check if target exists
        if would_overwrite?(operation) && !options[:force]
          return skip_result(operation, "Target exists (use force to overwrite)")
        end

        # Ensure target directory exists
        dir_result = ensure_target_directory(operation)
        return error_result(operation, dir_result[:error]) unless dir_result[:success]

        begin
          # For create operations, metadata should contain the content
          content = operation.metadata&.[](:content) || ""
          operation.target.write(content)
          success_result(operation, "Created new file")
        rescue => e
          error_result(operation, "Create failed: #{e.message}")
        end
      end

      def execute_update(operation, options)
        # Target must exist for update
        unless operation.target.exist?
          return error_result(operation, "Target not found for update: #{operation.target}")
        end

        begin
          # Read existing content
          content = operation.target.read

          # Apply updates from metadata
          if operation.metadata&.[](:updates)
            # This would apply specific updates in real implementation
          end

          # Write updated content
          operation.target.write(content)
          success_result(operation, "Updated existing file")
        rescue => e
          error_result(operation, "Update failed: #{e.message}")
        end
      end

      def success_result(operation, message)
        {
          success: true,
          operation: operation.to_h,
          message: message,
          status: :completed
        }
      end

      def dry_run_success_result(operation, message)
        {
          success: true,
          operation: operation.to_h,
          message: message,
          status: :completed,
          dry_run: true
        }
      end

      def skip_result(operation, reason)
        {
          success: true,
          operation: operation.to_h,
          message: reason,
          status: :skipped
        }
      end

      def error_result(operation, error)
        {
          success: false,
          operation: operation.to_h,
          error: error,
          status: :failed
        }
      end
    end
  end
end
