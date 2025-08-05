# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/git/git_orchestrator'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Checkout < Dry::CLI::Command
          desc 'Switch branches or restore working tree files across all repositories'

          option :debug, type: :boolean, default: false, aliases: ['d'],
            desc: 'Enable debug output for verbose error information'

          option :repository, type: :string, aliases: ['C'],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :quiet, type: :boolean, default: false, aliases: ['q'],
            desc: 'Quiet operation, suppress feedback messages'

          option :force, type: :boolean, default: false, aliases: ['f'],
            desc: 'Force checkout, throw away local changes'

          option :merge, type: :boolean, default: false, aliases: ['m'],
            desc: '3-way merge between current branch, working tree, and new branch'

          option :detach, type: :boolean, default: false,
            desc: 'Detach HEAD at named commit'

          option :create_branch, type: :string, aliases: ['b'],
            desc: 'Create and checkout a new branch'

          option :force_create_branch, type: :string, aliases: ['B'],
            desc: 'Create/reset and checkout a branch'

          option :orphan, type: :string,
            desc: 'Create a new orphan branch'

          option :track, type: :boolean, default: false, aliases: ['t'],
            desc: 'Set up tracking relationship'

          option :no_track, type: :boolean, default: false,
            desc: 'Do not set up tracking relationship'

          option :main_only, type: :boolean, default: false,
            desc: 'Process main repository only'

          option :submodules_only, type: :boolean, default: false,
            desc: 'Process submodules only'

          option :concurrent, type: :boolean, default: false,
            desc: 'Execute checkout operations concurrently across repositories'

          argument :branch_or_paths, type: :array, required: false,
            desc: 'Branch name, commit, or paths to checkout'

          example [
            'main',
            'feature-branch',
            '--create-branch new-feature',
            '--force-create-branch hotfix main',
            '--detach HEAD~1',
            '--orphan empty-branch',
            '-- file1.rb file2.rb',
            '--force main'
          ]

          def call(branch_or_paths: [], **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build checkout options
            checkout_options = build_checkout_options(branch_or_paths, options)

            # Execute checkout across repositories
            result = orchestrator.checkout(branch_or_paths, checkout_options)

            if result[:success]
              display_checkout_success(result, options)
              0
            else
              display_checkout_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_checkout_options(_branch_or_paths, options)
            checkout_opts = {
              capture_output: true
            }

            # Repository filtering
            checkout_opts[:repository] = options[:repository] if options[:repository]
            checkout_opts[:main_only] = options[:main_only] if options[:main_only]
            checkout_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Checkout behavior
            checkout_opts[:quiet] = options[:quiet] if options[:quiet]
            checkout_opts[:force] = options[:force] if options[:force]
            checkout_opts[:merge] = options[:merge] if options[:merge]
            checkout_opts[:detach] = options[:detach] if options[:detach]
            checkout_opts[:create_branch] = options[:create_branch] if options[:create_branch]
            checkout_opts[:force_create_branch] = options[:force_create_branch] if options[:force_create_branch]
            checkout_opts[:orphan] = options[:orphan] if options[:orphan]
            checkout_opts[:track] = options[:track] if options[:track]
            checkout_opts[:no_track] = options[:no_track] if options[:no_track]
            checkout_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            checkout_opts
          end

          def display_checkout_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_checkout_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_checkout_result(repo_name, repo_result, options)
              end
            end

            return unless result[:repositories_processed]

            repos_list = result[:repositories_processed].join(', ')
            puts "Checkout completed across repositories: #{repos_list}" unless options[:quiet]
          end

          def display_single_checkout_result(repo_name, result, options)
            return if options[:quiet]

            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Checkout completed successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || 'Checkout operation failed'
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_checkout_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Checkout failed: #{result[:error]}")
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
            puts "Partial success: Checkout completed in repositories: #{successful_names}"
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
