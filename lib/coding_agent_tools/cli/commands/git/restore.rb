# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/git/git_orchestrator'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Restore < Dry::CLI::Command
          desc 'Restore working tree files with intelligent path grouping'

          option :debug, type: :boolean, default: false, aliases: ['d'],
                         desc: 'Enable debug output for verbose error information'

          option :repository, type: :string, aliases: ['C'],
                              desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :source, type: :string, aliases: ['s'],
                          desc: 'Restore from a specific source tree (commit, branch, etc.)'

          option :staged, type: :boolean, default: false,
                          desc: 'Restore the staging area'

          option :worktree, type: :boolean, default: false,
                            desc: 'Restore the working tree (default behavior)'

          option :merge, type: :boolean, default: false, aliases: ['m'],
                         desc: '3-way merge when restoring'

          option :conflict, type: :string,
                            desc: 'How to handle conflicts (merge, diff3, zdiff3)'

          option :ours, type: :boolean, default: false,
                        desc: "Use 'ours' version for unmerged paths"

          option :theirs, type: :boolean, default: false,
                          desc: "Use 'theirs' version for unmerged paths"

          option :patch, type: :boolean, default: false, aliases: ['p'],
                         desc: 'Interactively select hunks to restore'

          option :quiet, type: :boolean, default: false, aliases: ['q'],
                         desc: 'Suppress output'

          option :progress, type: :boolean, default: false,
                            desc: 'Show progress status'

          option :main_only, type: :boolean, default: false,
                             desc: 'Process main repository only'

          option :submodules_only, type: :boolean, default: false,
                                   desc: 'Process submodules only'

          option :concurrent, type: :boolean, default: false,
                              desc: 'Execute restore operations concurrently across repositories'

          argument :pathspecs, type: :array, required: true,
                               desc: 'Files or directories to restore'

          example [
            'file.rb',
            '--staged modified_file.rb',
            '--source HEAD~1 old_version_file.rb',
            '--worktree --staged both_areas.rb',
            '--patch interactive_file.rb',
            '--ours conflicted_file.rb',
            'dev-handbook/guide.md dev-tools/lib/module.rb',
            '--concurrent --staged .'
          ]

          def call(pathspecs:, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build restore options
            restore_options = build_restore_options(pathspecs, options)

            # Execute restore across repositories
            result = orchestrator.restore(pathspecs, restore_options)

            if result[:success]
              display_restore_success(result, options)
              0
            else
              display_restore_errors(result, options)
              1
            end
          rescue StandardError => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_restore_options(_pathspecs, options)
            restore_opts = {
              capture_output: true
            }

            # Repository filtering
            restore_opts[:repository] = options[:repository] if options[:repository]
            restore_opts[:main_only] = options[:main_only] if options[:main_only]
            restore_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Restore behavior
            restore_opts[:source] = options[:source] if options[:source]
            restore_opts[:staged] = options[:staged] if options[:staged]
            restore_opts[:worktree] = options[:worktree] if options[:worktree]
            restore_opts[:merge] = options[:merge] if options[:merge]
            restore_opts[:conflict] = options[:conflict] if options[:conflict]
            restore_opts[:ours] = options[:ours] if options[:ours]
            restore_opts[:theirs] = options[:theirs] if options[:theirs]
            restore_opts[:patch] = options[:patch] if options[:patch]
            restore_opts[:quiet] = options[:quiet] if options[:quiet]
            restore_opts[:progress] = options[:progress] if options[:progress]
            restore_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            restore_opts
          end

          def display_restore_success(result, options)
            return if options[:quiet]

            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_restore_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_restore_result(repo_name, repo_result, options)
              end
            end

            return unless result[:repositories_processed]

            repos_list = result[:repositories_processed].join(', ')
            puts "Restore operations completed across repositories: #{repos_list}"
          end

          def display_single_restore_result(repo_name, result, options)
            return if options[:quiet]

            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Restore completed successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || 'Restore operation failed'
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_restore_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Restore failed: #{result[:error]}")
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
            puts "Partial success: Restore completed in repositories: #{successful_names}"
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
