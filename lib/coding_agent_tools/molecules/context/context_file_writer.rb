# frozen_string_literal: true

require "fileutils"
require "pathname"

module CodingAgentTools
  module Molecules
    module Context
      # ContextFileWriter - Molecule for writing context files with safety checks
      #
      # Responsibilities:
      # - Write context content to files with directory creation
      # - Provide progress reporting during write operations
      # - Implement atomic write operations for safety
      # - Validate output paths against security constraints
      class ContextFileWriter
        def initialize(security_validator = nil)
          @security_validator = security_validator
        end

        # Write content to a file with automatic directory creation
        #
        # @param content [String] Content to write
        # @param output_path [String] Path to write to
        # @param options [Hash] Write options
        # @option options [Boolean] :create_directories Auto-create directories (default: true)
        # @option options [Boolean] :atomic Write atomically using temp file (default: true)
        # @option options [Proc] :progress_callback Callback for progress reporting
        # @return [Hash] Write result with statistics
        def write_file(content, output_path, options = {})
          # Validate inputs first (before any processing)
          raise ArgumentError, "Content must be a string" unless content.is_a?(String)
          raise ArgumentError, "Output path must be provided" if output_path.nil? || output_path.empty?

          # Normalize options
          opts = {
            create_directories: true,
            atomic: true,
            progress_callback: nil
          }.merge(options)

          begin
            # Normalize path
            normalized_path = File.expand_path(output_path)
            
            # Validate security constraints if validator provided
            validate_output_path!(normalized_path) if @security_validator

            # Report progress
            report_progress(opts[:progress_callback], "Preparing to write to #{normalized_path}")

            # Create directories if needed
            if opts[:create_directories]
              create_directory_structure(normalized_path, opts[:progress_callback])
            end

            # Write content
            if opts[:atomic]
              write_atomically(content, normalized_path, opts[:progress_callback])
            else
              write_directly(content, normalized_path, opts[:progress_callback])
            end

            # Calculate and return statistics
            stats = calculate_file_stats(content, normalized_path)
            report_progress(opts[:progress_callback], "Successfully wrote #{stats[:size_formatted]} to #{normalized_path}")
            
            {
              success: true,
              path: normalized_path,
              **stats
            }
          rescue => e
            {
              success: false,
              path: normalized_path || output_path,
              error: e.message,
              size: 0,
              lines: 0,
              size_formatted: "0 bytes"
            }
          end
        end

        # Write multiple files in batch
        #
        # @param files [Array<Hash>] Array of file specs {content:, path:, options:}
        # @param global_options [Hash] Options applied to all files
        # @return [Array<Hash>] Array of write results
        def write_files(files, global_options = {})
          results = []
          total_files = files.length

          files.each_with_index do |file_spec, index|
            # Merge global options with file-specific options
            file_options = global_options.merge(file_spec[:options] || {})
            
            # Add batch progress callback
            if global_options[:progress_callback]
              file_options[:progress_callback] = ->(message) do
                global_options[:progress_callback].call("[#{index + 1}/#{total_files}] #{message}")
              end
            end

            result = write_file(file_spec[:content], file_spec[:path], file_options)
            results << result.merge(file_index: index)
          end

          results
        end

        # Check if a path is writable
        #
        # @param output_path [String] Path to check
        # @return [Boolean] true if path is writable
        def writable?(output_path)
          normalized_path = File.expand_path(output_path)
          
          # Check if file exists and is writable
          if File.exist?(normalized_path)
            File.writable?(normalized_path)
          else
            # Check if parent directory is writable
            parent_dir = File.dirname(normalized_path)
            File.exist?(parent_dir) && File.writable?(parent_dir)
          end
        rescue
          false
        end

        # Get information about what would be written
        #
        # @param content [String] Content that would be written
        # @param output_path [String] Path that would be written to
        # @return [Hash] Information about the planned write
        def preview_write(content, output_path)
          normalized_path = File.expand_path(output_path)
          stats = calculate_file_stats(content, normalized_path)
          
          {
            path: normalized_path,
            writable: writable?(normalized_path),
            exists: File.exist?(normalized_path),
            parent_exists: File.exist?(File.dirname(normalized_path)),
            **stats
          }
        end

        private

        # Validate output path using security validator
        #
        # @param path [String] Path to validate
        # @raise [Error] if path is not allowed
        def validate_output_path!(path)
          validated_path = @security_validator.validate_and_sanitize_path(path)
          if validated_path.nil?
            raise Error, "Output path not allowed: #{path}"
          end
        end

        # Report progress if callback provided
        #
        # @param callback [Proc] Progress callback
        # @param message [String] Progress message
        def report_progress(callback, message)
          callback&.call(message)
        end

        # Create directory structure for a file path
        #
        # @param file_path [String] File path needing directories
        # @param progress_callback [Proc] Progress callback
        def create_directory_structure(file_path, progress_callback)
          dir_path = File.dirname(file_path)
          return if File.exist?(dir_path)

          report_progress(progress_callback, "Creating directory: #{dir_path}")
          FileUtils.mkdir_p(dir_path)
        end

        # Write content atomically using a temporary file
        #
        # @param content [String] Content to write
        # @param output_path [String] Final output path
        # @param progress_callback [Proc] Progress callback
        def write_atomically(content, output_path, progress_callback)
          temp_path = "#{output_path}.tmp.#{Process.pid}.#{Time.now.to_f}"
          
          begin
            report_progress(progress_callback, "Writing to temporary file")
            File.write(temp_path, content)
            
            report_progress(progress_callback, "Moving to final location")
            File.rename(temp_path, output_path)
          ensure
            # Clean up temp file if it still exists
            File.unlink(temp_path) if File.exist?(temp_path)
          end
        end

        # Write content directly to file
        #
        # @param content [String] Content to write
        # @param output_path [String] Output path
        # @param progress_callback [Proc] Progress callback
        def write_directly(content, output_path, progress_callback)
          report_progress(progress_callback, "Writing content directly")
          File.write(output_path, content)
        end

        # Calculate file statistics
        #
        # @param content [String] File content
        # @param output_path [String] Output path
        # @return [Hash] File statistics
        def calculate_file_stats(content, output_path)
          size = content.bytesize
          
          # Count lines correctly - split by newlines and count non-empty segments
          if content.empty?
            lines = 0
          else
            lines = content.split("\n").length
          end
          
          {
            size: size,
            lines: lines,
            size_formatted: format_size(size),
            basename: File.basename(output_path),
            dirname: File.dirname(output_path)
          }
        end

        # Format size for display
        #
        # @param bytes [Integer] Size in bytes
        # @return [String] Formatted size
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
end