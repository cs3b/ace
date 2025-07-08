# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Add < Dry::CLI::Command
          desc "Add files to staging area with intelligent path grouping"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :all, type: :boolean, default: false, aliases: ["A"],
            desc: "Add all changes (new, modified, deleted)"

          option :update, type: :boolean, default: false, aliases: ["u"],
            desc: "Add only modified and deleted files"

          option :patch, type: :boolean, default: false, aliases: ["p"],
            desc: "Interactively choose hunks to add"

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Allow adding ignored files"

          option :concurrent, type: :boolean, default: false,
            desc: "Execute add operations concurrently across repositories"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          argument :files, type: :array, required: true,
            desc: "Files or directories to add"

          example [
            "file1.rb file2.rb",
            "--all",
            "--update",
            "dev-handbook/guide.md lib/auth.rb",
            "--patch lib/core.rb",
            "--concurrent dev-handbook/file.md dev-tools/lib/file.rb"
          ]

          def call(files:, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build add options
            add_options = build_add_options(files, options)

            # Execute add across repositories
            result = orchestrator.add(files, add_options)

            if result[:success]
              display_add_success(result, options)
              0
            else
              display_add_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_add_options(files, options)
            add_opts = {
              capture_output: true
            }

            # Repository filtering
            add_opts[:repository] = options[:repository] if options[:repository]
            add_opts[:main_only] = options[:main_only] if options[:main_only]
            add_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Add behavior
            add_opts[:all] = options[:all] if options[:all]
            add_opts[:update] = options[:update] if options[:update]
            add_opts[:patch] = options[:patch] if options[:patch]
            add_opts[:force] = options[:force] if options[:force]
            add_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            add_opts
          end

          def display_add_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_add_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_add_result(repo_name, repo_result, options)
              end
            end

            if result[:repositories_processed]
              repos_list = result[:repositories_processed].join(", ")
              puts "Files added across repositories: #{repos_list}"
            end
          end

          def display_single_add_result(repo_name, result, options)
            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Files added successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || "Add operation failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_add_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Add failed: #{result[:error]}")
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
                puts "Partial success: Files added in repositories: #{successful_names}"
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
