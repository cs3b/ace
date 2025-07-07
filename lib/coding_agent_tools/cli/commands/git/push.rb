# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Push < Dry::CLI::Command
          desc "Push changes to remote repositories concurrently"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Force push (use with caution)"

          option :dry_run, type: :boolean, default: false,
            desc: "Show what would be pushed without actually pushing"

          option :set_upstream, type: :boolean, default: false, aliases: ["u"],
            desc: "Set upstream tracking for new branches"

          option :tags, type: :boolean, default: false,
            desc: "Push tags along with commits"

          option :concurrent, type: :boolean, default: true,
            desc: "Execute push operations concurrently (default: true)"

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
            "--dry-run",
            "--force",
            "--set-upstream origin feature-branch",
            "--tags",
            "origin main",
            "--concurrent",
            "--main-only"
          ]

          def call(remote: nil, branch: nil, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)
            
            # Build push options
            push_options = build_push_options(remote, branch, options)
            
            # Execute push across repositories
            result = orchestrator.push(push_options)
            
            if result[:success]
              display_push_success(result, options)
              0
            else
              display_push_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_push_options(remote, branch, options)
            push_opts = {
              capture_output: true
            }
            
            # Repository filtering
            push_opts[:repository] = options[:repository] if options[:repository]
            push_opts[:main_only] = options[:main_only] if options[:main_only]
            push_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]
            
            # Push behavior
            push_opts[:remote] = remote if remote
            push_opts[:branch] = branch if branch
            push_opts[:force] = options[:force] if options[:force]
            push_opts[:dry_run] = options[:dry_run] if options[:dry_run]
            push_opts[:set_upstream] = options[:set_upstream] if options[:set_upstream]
            push_opts[:tags] = options[:tags] if options[:tags]
            push_opts[:concurrent] = options[:concurrent] if options.key?(:concurrent)
            
            push_opts
          end

          def display_push_success(result, options)
            if options[:dry_run]
              puts "Dry run - showing what would be pushed:"
            end
            
            if result[:results]
              result[:results].each do |repo_name, repo_result|
                next unless repo_result[:success]
                
                if repo_result[:commands]
                  # Multiple commands (from concurrent execution)
                  repo_result[:commands].each do |cmd_result|
                    display_single_push_result(repo_name, cmd_result, options)
                  end
                else
                  # Single command result
                  display_single_push_result(repo_name, repo_result, options)
                end
              end
            end
            
            unless options[:dry_run]
              if result[:repositories_processed]
                repos_list = result[:repositories_processed].join(", ")
                puts "Push completed across repositories: #{repos_list}"
              end
            end
          end

          def display_single_push_result(repo_name, result, options)
            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                output_lines = result[:stdout].strip.split("\n")
                output_lines.each { |line| puts "[#{repo_name}] #{line}" }
              elsif result[:output] && !result[:output].strip.empty?
                output_lines = result[:output].strip.split("\n")
                output_lines.each { |line| puts "[#{repo_name}] #{line}" }
              else
                status = options[:dry_run] ? "Would push" : "Push successful"
                puts "[#{repo_name}] #{status}"
              end
            else
              error_message = result[:error] || result[:stderr] || "Push operation failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_push_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Push failed: #{result[:error]}")
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
                status = options[:dry_run] ? "Would push to" : "Successfully pushed to"
                puts "Partial success: #{status} repositories: #{successful_names}"
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