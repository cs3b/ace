# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Fetch < Dry::CLI::Command
          desc "Fetch changes from remote repositories"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :all, type: :boolean, default: false,
            desc: "Fetch all remotes"

          option :prune, type: :boolean, default: false,
            desc: "Remove remote-tracking references that no longer exist on remote"

          option :tags, type: :boolean, default: false,
            desc: "Fetch tags"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          argument :remote, type: :string, required: false,
            desc: "Remote name to fetch from (optional)"

          example [
            "",
            "--all",
            "--prune",
            "--tags",
            "origin",
            "--repository dev-tools"
          ]

          def call(remote: nil, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build fetch options
            fetch_options = build_fetch_options(remote, options)

            # Execute fetch across repositories
            result = orchestrator.fetch(fetch_options)

            if result[:success]
              display_fetch_success(result, options)
              0
            else
              display_fetch_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_fetch_options(remote, options)
            fetch_opts = {
              capture_output: true
            }

            # Repository filtering
            fetch_opts[:repository] = options[:repository] if options[:repository]
            fetch_opts[:main_only] = options[:main_only] if options[:main_only]
            fetch_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Fetch behavior
            fetch_opts[:remote] = remote if remote
            fetch_opts[:all] = options[:all] if options[:all]
            fetch_opts[:prune] = options[:prune] if options[:prune]
            fetch_opts[:tags] = options[:tags] if options[:tags]

            fetch_opts
          end

          def display_fetch_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              if output.strip.empty?
                puts "[#{repo_name}] Fetch completed (no new changes)"
              else
                puts "[#{repo_name}] Fetch completed:"
                output.lines.each { |line| puts "  #{line.rstrip}" }
              end
            end

            if result[:repositories_processed]
              repos_list = result[:repositories_processed].join(", ")
              puts "Fetch completed across repositories: #{repos_list}"
            end
          end

          def display_fetch_errors(result, options)
            if result[:errors]
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
                puts "Partial success: Fetch completed in repositories: #{successful_names}"
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
