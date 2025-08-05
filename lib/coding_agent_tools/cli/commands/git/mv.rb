# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/git/git_orchestrator'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Mv < Dry::CLI::Command
          desc 'Move or rename files/directories with intelligent path grouping'

          option :debug, type: :boolean, default: false, aliases: ['d'],
            desc: 'Enable debug output for verbose error information'

          option :repository, type: :string, aliases: ['C'],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :force, type: :boolean, default: false, aliases: ['f'],
            desc: 'Force move even if target exists'

          option :dry_run, type: :boolean, default: false, aliases: ['n'],
            desc: 'Show what would be moved without actually moving'

          option :verbose, type: :boolean, default: false, aliases: ['v'],
            desc: 'Show verbose output'

          option :main_only, type: :boolean, default: false,
            desc: 'Process main repository only'

          option :submodules_only, type: :boolean, default: false,
            desc: 'Process submodules only'

          option :concurrent, type: :boolean, default: false,
            desc: 'Execute move operations concurrently across repositories'

          argument :source_and_destination, type: :array, required: true,
            desc: 'Source files/directories and destination'

          example [
            'old_file.rb new_file.rb',
            'src/old_dir/ src/new_dir/',
            'dev-handbook/guide.md dev-handbook/tutorial.md',
            '--force old_file.rb existing_file.rb',
            '--dry-run lib/old_module.rb lib/new_module.rb',
            '--concurrent dev-handbook/old.md dev-tools/lib/new.rb'
          ]

          def call(source_and_destination:, **options)
            if source_and_destination.length < 2
              error_output('Error: git mv requires at least a source and destination')
              return 1
            end

            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Split into source files and destination
            sources = source_and_destination[0..-2]
            destination = source_and_destination[-1]

            # Build mv options
            mv_options = build_mv_options(sources, destination, options)

            # Execute mv across repositories
            result = orchestrator.mv(sources, destination, mv_options)

            if result[:success]
              display_mv_success(result, options)
              0
            else
              display_mv_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_mv_options(_sources, _destination, options)
            mv_opts = {
              capture_output: true
            }

            # Repository filtering
            mv_opts[:repository] = options[:repository] if options[:repository]
            mv_opts[:main_only] = options[:main_only] if options[:main_only]
            mv_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Move behavior
            mv_opts[:force] = options[:force] if options[:force]
            mv_opts[:dry_run] = options[:dry_run] if options[:dry_run]
            mv_opts[:verbose] = options[:verbose] if options[:verbose]
            mv_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            mv_opts
          end

          def display_mv_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_mv_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_mv_result(repo_name, repo_result, options)
              end
            end

            return unless result[:repositories_processed]

            repos_list = result[:repositories_processed].join(', ')
            puts "Move operations completed across repositories: #{repos_list}"
          end

          def display_single_mv_result(repo_name, result, _options)
            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Move completed successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || 'Move operation failed'
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_mv_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Move failed: #{result[:error]}")
            end

            if result[:errors]
              # Multiple errors from different repositories
              result[:errors].each do |error_info|
                repo_name = error_info[:repository]
                message = error_info[:message]

                if options[:debug] && error_info[:error]
                  error_output("[#{repo_name}] Error: #{error_info[:error].class.name}: #{message}")
                  if error_info[:error].respond_to?(:backtrace)
                    error_info[:error].backtrace.each { |line| error_output("  #{line}") }
                  end
                else
                  error_output("[#{repo_name}] Error: #{message}")
                end
              end

              error_output('Use --debug flag for more information') unless options[:debug]
            end

            # Show any partial successes
            return unless result[:results]

            successful_repos = result[:results].select { |_, repo_result| repo_result[:success] }
            return unless successful_repos.any?

            successful_names = successful_repos.keys.join(', ')
            puts "Partial success: Move completed in repositories: #{successful_names}"
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
        end
      end
    end
  end
end
