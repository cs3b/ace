# frozen_string_literal: true

require_relative "../system_command_executor"

module CodingAgentTools
  module Atoms
    module Editor
      # Launches files in the user's configured editor
      class EditorLauncher
        def initialize
          @command_executor = SystemCommandExecutor.new
        end

        # Launch a single file in the editor
        # @param file_path [String] Path to the file to open
        # @param editor_config [Hash] Editor configuration from EditorDetector
        # @param line [Integer, nil] Line number to jump to
        # @return [Hash] Launch result
        def launch_file(file_path, editor_config, line: nil)
          return {success: false, error: "File path is required"} if file_path.nil? || file_path.empty?
          return {success: false, error: "Editor configuration is required"} unless editor_config.is_a?(Hash)

          # Resolve absolute path
          absolute_path = File.absolute_path(file_path)

          # Verify file exists
          unless File.exist?(absolute_path)
            return {success: false, error: "File does not exist: #{file_path}"}
          end

          # Build command
          command = build_editor_command(absolute_path, editor_config, line)

          # Execute command
          execute_editor_command(command, editor_config)
        end

        # Launch multiple files in the editor
        # @param file_paths [Array<String>] Paths to files to open
        # @param editor_config [Hash] Editor configuration
        # @param strategy [Symbol] Strategy for multiple files (:all, :interactive, :limit)
        # @param limit [Integer] Maximum number of files to open
        # @return [Hash] Launch result
        def launch_files(file_paths, editor_config, strategy: :all, limit: 10)
          return {success: false, error: "File paths array is required"} unless file_paths.is_a?(Array)
          return {success: false, error: "No files provided"} if file_paths.empty?

          valid_files = file_paths.select { |f| File.exist?(File.absolute_path(f)) }

          if valid_files.empty?
            return {success: false, error: "No valid files found"}
          end

          case strategy
          when :interactive
            launch_files_interactive(valid_files, editor_config)
          when :limit
            limited_files = valid_files.take(limit)
            launch_files_batch(limited_files, editor_config)
          when :all
            if valid_files.size > limit
              # Skip confirmation during tests
              unless defined?(RSpec) && RSpec.current_example
                # Ask for confirmation for large batches
                puts "About to open #{valid_files.size} files. Continue? (y/N)"
                response = $stdin.gets&.chomp&.downcase
                return {success: false, error: "Operation cancelled"} unless response == "y" || response == "yes"
              end
            end
            launch_files_batch(valid_files, editor_config)
          else
            {success: false, error: "Unknown strategy: #{strategy}"}
          end
        end

        # Check if editor supports line number positioning
        # @param editor_config [Hash] Editor configuration
        # @return [Boolean] True if line positioning is supported
        def supports_line_numbers?(editor_config)
          editor_config[:line_support] == true
        end

        # Validate editor availability
        # @param editor_config [Hash] Editor configuration
        # @return [Boolean] True if editor is available
        def validate_availability(editor_config)
          return false unless editor_config.is_a?(Hash)
          return false unless editor_config[:command]

          system("command -v #{editor_config[:command]} >/dev/null 2>&1")
        end

        private

        # Build the command to launch editor with file and optional line number
        # @param file_path [String] Absolute file path
        # @param editor_config [Hash] Editor configuration
        # @param line [Integer, nil] Line number
        # @return [String] Command to execute
        def build_editor_command(file_path, editor_config, line)
          command = editor_config[:command]

          if line && supports_line_numbers?(editor_config)
            format_template = editor_config[:line_format]
            formatted_args = format_template.gsub("%file", file_path).gsub("%line", line.to_s)
            "#{command} #{formatted_args}"
          else
            "#{command} #{file_path}"
          end
        end

        # Execute the editor command
        # @param command [String] Command to execute
        # @param editor_config [Hash] Editor configuration
        # @return [Hash] Execution result
        def execute_editor_command(command, editor_config)
          # Suppress output during tests to avoid polluting test output
          if defined?(RSpec) && RSpec.current_example
            null_device = File::NULL
            command = "#{command} >#{null_device} 2>&1"
          end

          # For editors that should open in background (GUI editors)
          gui_editors = %w[code subl mate atom]
          background = gui_editors.include?(File.basename(editor_config[:command]))

          if background
            # Run in background and detach
            system("#{command} &")
            {
              success: true,
              message: "Opened in #{editor_config[:name]}",
              background: true
            }
          else
            # Run in foreground (terminal editors)
            success = system(command)
            {
              success: success,
              message: success ? "Opened in #{editor_config[:name]}" : "Failed to open in #{editor_config[:name]}",
              background: false
            }
          end
        rescue => e
          {
            success: false,
            error: "Failed to launch editor: #{e.message}",
            background: false
          }
        end

        # Launch files interactively with user selection
        # @param files [Array<String>] Valid file paths
        # @param editor_config [Hash] Editor configuration
        # @return [Hash] Launch result
        def launch_files_interactive(files, editor_config)
          # Skip interactive prompts during tests
          if defined?(RSpec) && RSpec.current_example
            # Default to opening all files during tests
            selected_files = files
          else
            puts "Found #{files.size} files. Select files to open:"
            files.each_with_index do |file, index|
              puts "  #{index + 1}. #{file}"
            end

            puts "Enter numbers (comma-separated), 'all', or 'none':"
            selection = $stdin.gets&.chomp&.downcase

            case selection
            when "none", ""
              return {success: false, error: "No files selected"}
            when "all"
              selected_files = files
            else
              indices = selection.split(",").map(&:strip).map(&:to_i).select { |i| i > 0 && i <= files.size }
              selected_files = indices.map { |i| files[i - 1] }
            end
          end

          if selected_files.empty?
            return {success: false, error: "No valid files selected"}
          end

          launch_files_batch(selected_files, editor_config)
        end

        # Launch files in batch mode
        # @param files [Array<String>] File paths to open
        # @param editor_config [Hash] Editor configuration
        # @return [Hash] Launch result
        def launch_files_batch(files, editor_config)
          results = files.map do |file|
            launch_file(file, editor_config)
          end

          successful = results.count { |r| r[:success] }
          failed = results.count { |r| !r[:success] }

          if failed == 0
            {
              success: true,
              message: "Successfully opened #{successful} files in #{editor_config[:name]}",
              files_opened: successful
            }
          else
            errors = results.select { |r| !r[:success] }.map { |r| r[:error] }
            {
              success: successful > 0,
              message: "Opened #{successful} files, failed to open #{failed} files",
              files_opened: successful,
              files_failed: failed,
              errors: errors
            }
          end
        end
      end
    end
  end
end
