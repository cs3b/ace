# frozen_string_literal: true

require 'dry/cli'
require 'fileutils'
require_relative '../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      # Install dotfiles command for setting up configuration files in new projects
      class InstallDotfiles < Dry::CLI::Command
        desc 'Install configuration files (.coding-agent/*.yml) in the current project'

        option :force, type: :boolean, default: false, aliases: ['f'],
                       desc: 'Overwrite existing configuration files'

        option :dry_run, type: :boolean, default: false,
                         desc: 'Show what would be copied without actually copying'

        option :debug, type: :boolean, default: false, aliases: ['d'],
                       desc: 'Enable debug output for verbose information'

        example [
          '',
          '--force',
          '--dry-run',
          '--debug'
        ]

        def call(**options)
          # Find project root
          project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          template_dir = find_template_directory(project_root)

          unless template_dir
            error_output('Error: Could not find dotfiles templates.')
            error_output('Expected location: dev-handbook/.meta/tpl/dotfiles/')
            return 1
          end

          target_dir = File.join(project_root, '.coding-agent')

          if options[:debug]
            debug_output("Debug: Project root: #{project_root}")
            debug_output("Debug: Template directory: #{template_dir}")
            debug_output("Debug: Target directory: #{target_dir}")
          end

          # Create target directory if it doesn't exist
          unless Dir.exist?(target_dir)
            if options[:dry_run]
              info_output("Would create directory: #{target_dir}")
            else
              FileUtils.mkdir_p(target_dir)
              info_output("Created directory: #{target_dir}")
            end
          end

          # Find all template files
          template_files = Dir.glob(File.join(template_dir, '*.yml'))

          if template_files.empty?
            error_output("Error: No template files found in #{template_dir}")
            return 1
          end

          copied_count = 0
          skipped_count = 0

          template_files.each do |template_file|
            filename = File.basename(template_file)
            target_file = File.join(target_dir, filename)

            if File.exist?(target_file) && !options[:force]
              if options[:dry_run]
                info_output("Would skip existing file: #{filename}")
              else
                info_output("Skipping existing file: #{filename} (use --force to overwrite)")
              end
              skipped_count += 1
              next
            end

            if options[:dry_run]
              info_output("Would copy: #{filename}")
            else
              FileUtils.cp(template_file, target_file)
              info_output("Copied: #{filename}")
            end
            copied_count += 1
          end

          # Summary
          info_output('')
          if options[:dry_run]
            info_output('Dry run complete:')
            info_output("  Would copy: #{copied_count} files")
            info_output("  Would skip: #{skipped_count} files")
          else
            info_output('Installation complete:')
            info_output("  Copied: #{copied_count} files")
            info_output("  Skipped: #{skipped_count} files")
            info_output('')
            info_output('Configuration files are now available in .coding-agent/')
            info_output("You can customize them for your project's specific needs.")
          end

          0
        rescue StandardError => e
          handle_error(e, options[:debug])
          1
        end

        private

        def find_template_directory(project_root)
          # Look for the template directory in the project
          candidate_paths = [
            File.join(project_root, 'dev-handbook', '.meta', 'tpl', 'dotfiles'),
            File.join(project_root, '.meta', 'tpl', 'dotfiles'),
            File.join(project_root, 'templates', 'dotfiles')
          ]

          candidate_paths.find { |path| Dir.exist?(path) && !Dir.glob(File.join(path, '*.yml')).empty? }
        end

        def handle_error(error, debug_enabled)
          if debug_enabled
            error_output("Error: #{error.class.name}: #{error.message}")
            error_output("\nBacktrace:")
            error.backtrace.each { |line| error_output("  #{line}") }
          else
            error_output("Error: #{error.message}")
            error_output('Use --debug flag for more information')
          end
        end

        def error_output(message)
          warn message
        end

        def debug_output(message)
          # Allow debug output if explicitly enabled, even in test environment
          # This ensures tests that check debug functionality still work
          $stdout.puts message
        end

        def test_environment?
          ENV['CI'] || defined?(RSpec) || ENV['RAILS_ENV'] == 'test' || ENV['RACK_ENV'] == 'test'
        end

        def debug_explicitly_enabled?
          ENV['DEBUG'] == 'true' || ENV['TEST_DEBUG'] == 'true'
        end

        def info_output(message)
          $stdout.puts message
        end
      end
    end
  end
end
