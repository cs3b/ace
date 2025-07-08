# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Rm < Dry::CLI::Command
          desc "Remove files from working tree and index with intelligent path grouping"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Override the up-to-date check"

          option :dry_run, type: :boolean, default: false, aliases: ["n"],
            desc: "Show what would be removed without actually removing"

          option :recursive, type: :boolean, default: false, aliases: ["r"],
            desc: "Allow recursive removal of directories"

          option :cached, type: :boolean, default: false,
            desc: "Remove from index only, keep working tree files"

          option :ignore_unmatch, type: :boolean, default: false,
            desc: "Exit with zero status even if no files matched"

          option :quiet, type: :boolean, default: false, aliases: ["q"],
            desc: "Suppress output"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          option :concurrent, type: :boolean, default: false,
            desc: "Execute remove operations concurrently across repositories"

          argument :files, type: :array, required: true,
            desc: "Files or directories to remove"

          example [
            "file.rb",
            "--recursive old_directory/",
            "--cached staged_file.rb",
            "--force modified_file.rb",
            "--dry-run lib/old_module.rb",
            "dev-handbook/obsolete.md dev-tools/lib/deprecated.rb",
            "--concurrent --recursive test_dirs/"
          ]

          def call(files:, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build rm options
            rm_options = build_rm_options(files, options)

            # Execute rm across repositories
            result = orchestrator.rm(files, rm_options)

            if result[:success]
              display_rm_success(result, options)
              0
            else
              display_rm_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_rm_options(files, options)
            rm_opts = {
              capture_output: true
            }

            # Repository filtering
            rm_opts[:repository] = options[:repository] if options[:repository]
            rm_opts[:main_only] = options[:main_only] if options[:main_only]
            rm_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Remove behavior
            rm_opts[:force] = options[:force] if options[:force]
            rm_opts[:dry_run] = options[:dry_run] if options[:dry_run]
            rm_opts[:recursive] = options[:recursive] if options[:recursive]
            rm_opts[:cached] = options[:cached] if options[:cached]
            rm_opts[:ignore_unmatch] = options[:ignore_unmatch] if options[:ignore_unmatch]
            rm_opts[:quiet] = options[:quiet] if options[:quiet]
            rm_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            rm_opts
          end

          def display_rm_success(result, options)
            return if options[:quiet]

            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_rm_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_rm_result(repo_name, repo_result, options)
              end
            end

            if result[:repositories_processed]
              repos_list = result[:repositories_processed].join(", ")
              puts "Remove operations completed across repositories: #{repos_list}"
            end
          end

          def display_single_rm_result(repo_name, result, options)
            return if options[:quiet]

            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Remove completed successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || "Remove operation failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_rm_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Remove failed: #{result[:error]}")
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
                puts "Partial success: Remove completed in repositories: #{successful_names}"
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
