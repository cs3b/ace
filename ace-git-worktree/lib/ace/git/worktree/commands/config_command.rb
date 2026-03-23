# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # Config command
        #
        # Displays and validates worktree configuration.
        # Shows current settings, configuration file locations, and validation results.
        #
        # @example Show current configuration
        #   ConfigCommand.new.run(["--show"])
        #
        # @example Validate configuration
        #   ConfigCommand.new.run(["--validate"])
        class ConfigCommand
          # Initialize a new ConfigCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
          end

          # Run the config command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            # Default to showing configuration if no action specified
            options[:show] = true unless options[:validate] || options[:show] || options[:files]

            validate_options(options)

            results = []

            if options[:show]
              results << show_configuration
            end

            if options[:validate]
              results << validate_configuration
            end

            if options[:files]
              results << show_configuration_files
            end

            # Return success if all operations succeeded
            (results.all? { |result| result == 0 }) ? 0 : 1
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            puts
            show_help
            1
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          # Show help for the config command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree config - Manage worktree configuration

              USAGE:
                  ace-git-worktree config [OPTIONS]

              ACTIONS:
                  --show                  Show current configuration (default)
                  --validate              Validate configuration
                  --files                 Show configuration file locations

              OPTIONS:
                  --verbose, -v           Show detailed information
                  --help, -h              Show this help message

              EXAMPLES:
                  # Show current configuration
                  ace-git-worktree config
                  ace-git-worktree config --show

                  # Validate configuration
                  ace-git-worktree config --validate

                  # Show configuration file locations
                  ace-git-worktree config --files

                  # Show everything
                  ace-git-worktree config --show --validate --files

              CONFIGURATION FILES:
                  .ace/git/worktree.yml          Project-specific configuration
                  .ace-defaults/git/worktree.yml  Example configuration template
                  ~/.ace/git/worktree.yml         User-specific configuration

              CONFIGURATION OPTIONS:
                  git.worktree.root_path         Worktree root directory
                  git.worktree.mise_trust_auto   Automatic mise trust
                  git.worktree.task.*            Task-related settings
                  git.worktree.cleanup.*         Cleanup behavior settings

              VALIDATION:
                  Checks for:
                  • Valid configuration structure
                  • Required configuration fields
                  • Accessible worktree root directory
                  • Valid template variables
                  • Consistent settings

              For configuration examples, see .ace-defaults/git/worktree.yml
            HELP
            0
          end

          private

          # Parse command line arguments
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Parsed options
          def parse_arguments(args)
            options = {
              show: false,
              validate: false,
              files: false,
              verbose: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--show"
                options[:show] = true
              when "--validate"
                options[:validate] = true
              when "--files"
                options[:files] = true
              when "--verbose", "-v"
                options[:verbose] = true
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                # Accept subcommand arguments (show, validate) as aliases for flags
                case arg
                when "show"
                  options[:show] = true
                when "validate"
                  options[:validate] = true
                else
                  raise ArgumentError, "Unexpected argument: #{arg}"
                end
              end

              i += 1
            end

            options
          end

          # Validate parsed options
          #
          # @param options [Hash] Parsed options
          def validate_options(options)
            # No specific validation needed for config command
          end

          # Show current configuration
          #
          # @return [Integer] Exit code
          def show_configuration
            puts "Current Worktree Configuration:"
            puts "=" * 50

            config = @manager.configuration

            # Basic settings
            puts "Root Path: #{config.root_path}"
            puts "Absolute Root: #{config.absolute_root_path}"
            puts "Mise Trust Auto: #{config.mise_trust_auto? ? "enabled" : "disabled"}"
            puts

            # Task settings
            puts "Task Settings:"
            puts "  Directory Format: #{config.directory_format}"
            puts "  Branch Format: #{config.branch_format}"
            puts "  Auto Mark In Progress: #{config.auto_mark_in_progress? ? "enabled" : "disabled"}"
            puts "  Auto Commit Task: #{config.auto_commit_task? ? "enabled" : "disabled"}"
            puts "  Add Worktree Metadata: #{config.add_worktree_metadata? ? "enabled" : "disabled"}"
            puts

            if config.auto_commit_task?
              puts "Commit Message Format:"
              puts "  #{config.commit_message_format}"
              puts
            end

            # Cleanup settings
            puts "Cleanup Settings:"
            puts "  On Merge: #{config.cleanup_on_merge? ? "enabled" : "disabled"}"
            puts "  On Delete: #{config.cleanup_on_delete? ? "enabled" : "disabled"}"
            puts

            # Template variables
            puts "Available Template Variables:"
            puts "  {id}        - Task numeric ID (e.g., 081)"
            puts "  {task_id}   - Full task ID (e.g., task.081)"
            puts "  {slug}      - URL-safe slug from task title"
            puts

            # Example usage
            puts "Example Usage:"
            task_id = "081"
            task_slug = "fix-authentication-bug"
            puts "  Directory: #{config.directory_format.gsub("{id}", task_id).gsub("{slug}", task_slug)}"
            puts "  Branch: #{config.branch_format.gsub("{id}", task_id).gsub("{slug}", task_slug)}"
            puts

            0
          rescue => e
            puts "Error showing configuration: #{e.message}"
            1
          end

          # Validate configuration
          #
          # @return [Integer] Exit code
          def validate_configuration
            puts "Configuration Validation:"
            puts "=" * 30

            result = @manager.validate_configuration

            if result[:success]
              puts "✅ Configuration is valid"
              puts

              if result[:errors].any?
                puts "Warnings:"
                result[:errors].each { |error| puts "  ⚠️  #{error}" }
              end
            else
              puts "❌ Configuration validation failed"
              puts
              puts "Errors:"
              result[:errors].each { |error| puts "  ❌ #{error}" }
              puts

              puts "Suggestions:"
              puts "  • Check .ace/git/worktree.yml for syntax errors"
              puts "  • Ensure all required fields are present"
              puts "  • Verify template variables are correct"
              puts "  • Check that worktree root directory is accessible"
              puts "  • See .ace-defaults/git/worktree.yml for examples"
              puts

              return 1
            end

            puts

            0
          rescue => e
            puts "Error validating configuration: #{e.message}"
            1
          end

          # Show configuration file locations
          #
          # @return [Integer] Exit code
          def show_configuration_files
            puts "Configuration Files:"
            puts "=" * 20

            # Get configuration files from config loader
            config_loader = @manager.instance_variable_get(:@config_loader)
            config_files = config_loader.config_files

            config_files.each do |file|
              if File.exist?(file)
                puts "✅ #{file} (exists)"

                # Show some info about the file
                begin
                  stat = File.stat(file)
                  size = stat.size
                  mtime = stat.mtime.strftime("%Y-%m-%d %H:%M:%S")
                  puts "   Size: #{format_bytes(size)}"
                  puts "   Modified: #{mtime}"

                  # Check if it's the active config
                  if file.include?(".ace/git/worktree.yml")
                    puts "   📍 Active project configuration"
                  elsif file.include?(".ace-defaults/")
                    puts "   📋 Example template"
                  elsif file.include?("~/.ace/")
                    puts "   👤 User configuration"
                  end
                rescue => e
                  puts "   ⚠️  Error reading file info: #{e.message}"
                end
              else
                puts "❌ #{file} (not found)"
              end
              puts
            end

            # Show configuration cascade order
            puts "Configuration Priority (highest to lowest):"
            puts "  1. .ace/git/worktree.yml (project-specific)"
            puts "  2. ~/.ace/git/worktree.yml (user-specific)"
            puts "  3. .ace-defaults/git/worktree.yml (defaults)"
            puts
            puts "Note: Later configurations override earlier ones."
            puts

            0
          rescue => e
            puts "Error showing configuration files: #{e.message}"
            1
          end

          # Format bytes in human readable format
          #
          # @param bytes [Integer] Number of bytes
          # @return [String] Formatted string
          def format_bytes(bytes)
            units = %w[B KB MB GB]
            size = bytes.to_f
            unit_index = 0

            while size >= 1024 && unit_index < units.length - 1
              size /= 1024
              unit_index += 1
            end

            "#{size.round(1)} #{units[unit_index]}"
          end
        end
      end
    end
  end
end
