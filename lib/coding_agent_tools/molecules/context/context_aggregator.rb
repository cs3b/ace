# frozen_string_literal: true

require_relative "../../atoms/code/file_content_reader"
require_relative "../../atoms/system_command_executor"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Context
      # ContextAggregator - Molecule for combining file contents and command outputs
      #
      # Responsibilities:
      # - Expand glob patterns in file lists
      # - Read file contents with error handling
      # - Execute commands and capture output
      # - Aggregate all context into structured format
      class ContextAggregator
        def initialize(options = {})
          @file_reader = Atoms::Code::FileContentReader.new
          @command_executor = Atoms::SystemCommandExecutor.new
          @max_size = options[:max_size] || 1048576  # 1MB default
          @timeout = options[:timeout] || 30
          @project_root = Atoms::ProjectRootDetector.find_project_root
        end

        # Aggregate context from template data
        #
        # @param template [Hash] Parsed template with :files and :commands
        # @return [Hash] {files: Array, commands: Array, errors: Array}
        def aggregate(template)
          result = {
            files: [],
            commands: [],
            errors: []
          }

          # Process files
          process_files(template[:files], result) unless template[:files].empty?

          # Process commands
          process_commands(template[:commands], result) unless template[:commands].empty?

          result
        end

        private

        # Process files list with glob expansion
        #
        # @param files_list [Array<String>] List of file paths/patterns
        # @param result [Hash] Result hash to populate
        def process_files(files_list, result)
          files_list.each do |file_pattern|
            expanded_files = expand_file_pattern(file_pattern)

            if expanded_files.empty?
              result[:errors] << "No files found matching pattern: #{file_pattern}"
              next
            end

            expanded_files.each do |file_path|
              process_single_file(file_path, result)
            end
          rescue => e
            result[:errors] << "Error processing file pattern '#{file_pattern}': #{e.message}"
          end
        end

        # Process single file
        #
        # @param file_path [String] Path to file
        # @param result [Hash] Result hash to populate
        def process_single_file(file_path, result)
          # Check file size before reading
          if File.exist?(file_path) && File.size(file_path) > @max_size
            result[:errors] << "File too large: #{file_path} (#{File.size(file_path)} bytes, max: #{@max_size})"
            return
          end

          # Skip binary files
          if binary_file?(file_path)
            result[:errors] << "Skipping binary file: #{file_path}"
            return
          end

          file_result = @file_reader.read(file_path)

          if file_result[:success]
            result[:files] << {
              path: file_path,
              content: file_result[:content],
              size: file_result[:content].bytesize
            }
          else
            result[:errors] << "Failed to read #{file_path}: #{file_result[:error]}"
          end
        rescue => e
          result[:errors] << "Error reading file '#{file_path}': #{e.message}"
        end

        # Process commands list
        #
        # @param commands_list [Array<String>] List of commands to execute
        # @param result [Hash] Result hash to populate
        def process_commands(commands_list, result)
          commands_list.each do |command|
            process_single_command(command, result)
          rescue => e
            result[:errors] << "Error processing command '#{command}': #{e.message}"
          end
        end

        # Process single command
        #
        # @param command [String] Command to execute
        # @param result [Hash] Result hash to populate
        def process_single_command(command, result)
          command_result = @command_executor.execute(command, timeout: @timeout, working_dir: @project_root)

          context_entry = {
            command: command,
            success: command_result[:success]
          }

          context_entry[:output] = command_result[:output] || ""
          if command_result[:success]
          else
            context_entry[:error] = command_result[:error]
            result[:errors] << "Command failed: #{command} - #{command_result[:error]}"
          end

          result[:commands] << context_entry
        rescue => e
          result[:errors] << "Error executing command '#{command}': #{e.message}"
        end

        # Expand file pattern using glob
        #
        # @param pattern [String] File pattern (may include globs)
        # @return [Array<String>] List of matching file paths
        def expand_file_pattern(pattern)
          # Resolve pattern relative to project root
          absolute_pattern = if pattern.start_with?("/")
            pattern
          else
            File.join(@project_root, pattern)
          end

          # If pattern contains glob characters, use Dir.glob
          if pattern.include?("*") || pattern.include?("?") || pattern.include?("[")
            Dir.glob(absolute_pattern).select { |path| File.file?(path) }
          else
            # Single file path
            (File.exist?(absolute_pattern) && File.file?(absolute_pattern)) ? [absolute_pattern] : []
          end
        end

        # Check if file is binary
        #
        # @param file_path [String] Path to file
        # @return [Boolean] true if file appears to be binary
        def binary_file?(file_path)
          return false unless File.exist?(file_path)
          return true if File.zero?(file_path)

          # Read first 8192 bytes to check for null bytes
          sample = File.open(file_path, "rb") { |f| f.read(8192) }
          return false if sample.nil? || sample.empty?

          # Check for null bytes (common in binary files)
          sample.include?("\x00")
        rescue
          # If we can't read the file to check, assume it's not binary
          false
        end
      end
    end
  end
end
