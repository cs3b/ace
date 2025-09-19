# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Commit < Dry::CLI::Command
          desc "Commit changes across repositories with LLM-generated messages"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :intention, type: :string, aliases: ["i"],
            desc: "Intention context for commit message generation"

          option :local, type: :boolean, default: false, aliases: ["l"],
            desc: "Use local LM Studio model (lmstudio:mistral-small-3.1-24b-instruct-2503)"

          option :no_edit, type: :boolean, default: false, aliases: ["n"],
            desc: "Skip editor and commit directly with generated message"

          option :message, type: :string, aliases: ["m"],
            desc: "Use provided message instead of LLM generation"

          option :all, type: :boolean, default: false, aliases: ["a"],
            desc: "Stage all changes before committing"

          option :model, type: :string,
            desc: "Specify LLM model (provider:model format, e.g., 'google:gemini-2.0-flash-lite', 'anthropic:claude-3.5-sonnet')"

          option :concurrent, type: :boolean, default: false,
            desc: "Execute commits concurrently across repositories"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          option :repo_only, type: :boolean, default: false,
            desc: "Process only the current repository instead of all repositories"

          argument :files, type: :array, required: false,
            desc: "Specific files to commit (optional)"

          example [
            "",
            "--intention 'implement user authentication'",
            "--message 'fix typo in documentation'",
            "--intention 'refactor database layer'",
            "dev-handbook/guide.md lib/auth.rb",
            "--concurrent --intention 'update across all repos'",
            "--repository dev-tools --message 'update gem version'",
            "--repo-only --intention 'local change only'",
            "--model 'anthropic:claude-3.5-sonnet' --intention 'complex refactoring'",
            "--model 'google:gemini-2.5-flash' --intention 'simple fix'"
          ]

          def call(files: [], **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build commit options
            commit_options = build_commit_options(files, options)

            # Execute commit across repositories
            result = orchestrator.commit(commit_options)

            if result[:success]
              display_commit_success(result, options)
              0
            else
              display_commit_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_commit_options(files, options)
            commit_opts = {
              files: files,
              capture_output: true
            }

            # Repository filtering
            commit_opts[:repository] = options[:repository] if options[:repository]
            commit_opts[:main_only] = options[:main_only] if options[:main_only]
            commit_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]
            commit_opts[:repo_only] = options[:repo_only]

            # Commit behavior
            commit_opts[:all] = options[:all] if options[:all]
            commit_opts[:message] = options[:message] if options[:message]
            commit_opts[:no_edit] = options[:no_edit] if options[:no_edit]
            commit_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            # LLM options
            commit_opts[:intention] = options[:intention] if options[:intention]

            # Handle model selection
            if options[:model]
              commit_opts[:model] = options[:model]
            elsif options[:local]
              # Use local LM Studio model when --local flag is specified
              commit_opts[:model] = "lmstudio:mistral-small-3.1-24b-instruct-2503"
            end
            # Otherwise, use the default model (google:gemini-2.0-flash-lite)
            commit_opts[:debug] = options[:debug] if options[:debug]

            commit_opts
          end

          def display_commit_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_commit_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_commit_result(repo_name, repo_result, options)
              end
            end

            return unless result[:repositories_processed]

            repos_list = result[:repositories_processed].join(", ")
            puts "\nCommit completed across repositories: #{repos_list}"
          end

          def display_single_commit_result(repo_name, result, _options)
            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Commit successful"
              end
            else
              error_message = result[:error] || result[:stderr] || "Commit failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_commit_errors(result, options)
            has_errors = false

            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Commit failed: #{result[:error]}")
              has_errors = true
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

              error_output("Use --debug flag for more information") unless options[:debug]
              has_errors = true
            end

            # Show any partial successes (only once)
            return unless result[:results] && has_errors

            successful_repos = result[:results].select { |_, repo_result| repo_result[:success] }
            return unless successful_repos.any?

            successful_names = successful_repos.keys.join(", ")
            puts "Partial success: Committed in repositories: #{successful_names}"
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
