# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Pull < Dry::CLI::Command
          desc "Pull changes from remote repositories concurrently"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :rebase, type: :boolean, default: false, aliases: ["r"],
            desc: "Rebase instead of merge"

          option :ff_only, type: :boolean, default: false,
            desc: "Only allow fast-forward merges"

          option :no_commit, type: :boolean, default: false,
            desc: "Don't commit automatic merge"

          option :strategy, type: :string,
            desc: "Merge strategy to use"

          option :concurrent, type: :boolean, default: true,
            desc: "Execute pull operations concurrently (default: true)"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          argument :remote, type: :string, required: false,
            desc: "Remote name (default: origin)"

          argument :branch, type: :string, required: false,
            desc: "Branch name (default: current branch)"

          example [
            "",
            "--rebase",
            "--ff-only",
            "--no-commit",
            "upstream main",
            "--concurrent",
            "--strategy=recursive"
          ]

          def call(remote: nil, branch: nil, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build pull options
            pull_options = build_pull_options(remote, branch, options)

            # Execute pull across repositories
            result = orchestrator.pull(pull_options)

            if result[:success]
              display_pull_success(result, options)
              0
            else
              display_pull_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_pull_options(remote, branch, options)
            pull_opts = {
              capture_output: true
            }

            # Repository filtering
            pull_opts[:repository] = options[:repository] if options[:repository]
            pull_opts[:main_only] = options[:main_only] if options[:main_only]
            pull_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Pull behavior
            pull_opts[:remote] = remote if remote
            pull_opts[:branch] = branch if branch
            pull_opts[:rebase] = options[:rebase] if options[:rebase]
            pull_opts[:ff_only] = options[:ff_only] if options[:ff_only]
            pull_opts[:no_commit] = options[:no_commit] if options[:no_commit]
            pull_opts[:strategy] = options[:strategy] if options[:strategy]
            pull_opts[:concurrent] = options[:concurrent] if options.key?(:concurrent)

            pull_opts
          end

          def display_pull_success(result, options)
            if result[:results]
              result[:results].each do |repo_name, repo_result|
                next unless repo_result[:success]

                if repo_result[:commands]
                  # Multiple commands (from concurrent execution)
                  repo_result[:commands].each do |cmd_result|
                    display_single_pull_result(repo_name, cmd_result, options)
                  end
                else
                  # Single command result
                  display_single_pull_result(repo_name, repo_result, options)
                end
              end
            end

            if result[:repositories_processed]
              repos_list = result[:repositories_processed].join(", ")
              puts "Pull completed across repositories: #{repos_list}"
            end
          end

          def display_single_pull_result(repo_name, result, options)
            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                output_lines = result[:stdout].strip.split("\n")
                output_lines.each { |line| puts "[#{repo_name}] #{line}" }
              elsif result[:output] && !result[:output].strip.empty?
                output_lines = result[:output].strip.split("\n")
                output_lines.each { |line| puts "[#{repo_name}] #{line}" }
              else
                puts "[#{repo_name}] Pull successful"
              end
            else
              error_message = result[:error] || result[:stderr] || "Pull operation failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_pull_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Pull failed: #{result[:error]}")
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

              unless options[:debug]
                error_output("Use --debug flag for more information")
              end
            end

            # Show any partial successes
            if result[:results]
              successful_repos = result[:results].select { |_, repo_result| repo_result[:success] }
              if successful_repos.any?
                successful_names = successful_repos.keys.join(", ")
                puts "Partial success: Pull completed in repositories: #{successful_names}"
              end
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
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
