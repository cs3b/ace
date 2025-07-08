# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Diff < Dry::CLI::Command
          desc "Show differences across repositories"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :staged, type: :boolean, default: false,
            desc: "Show staged changes only"

          option :name_only, type: :boolean, default: false,
            desc: "Show only names of changed files"

          option :stat, type: :boolean, default: false,
            desc: "Show diffstat"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          example [
            "",
            "--staged",
            "--name-only",
            "--stat",
            "--repository dev-tools",
            "--main-only"
          ]

          def call(**options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build diff options
            diff_options = build_diff_options(options)

            # Execute diff across repositories
            result = orchestrator.diff(diff_options)

            if result[:success]
              display_diff_output(result, options)
              0
            else
              display_diff_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_diff_options(options)
            diff_opts = {
              capture_output: true
            }

            # Repository filtering
            diff_opts[:repository] = options[:repository] if options[:repository]
            diff_opts[:main_only] = options[:main_only] if options[:main_only]
            diff_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Git diff specific options
            diff_opts[:staged] = options[:staged] if options[:staged]
            diff_opts[:name_only] = options[:name_only] if options[:name_only]
            diff_opts[:stat] = options[:stat] if options[:stat]

            diff_opts
          end

          def display_diff_output(result, options)
            has_changes = false

            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              next if output.strip.empty?

              has_changes = true

              if options[:name_only]
                puts "[#{repo_name}] Changed files:"
                output.lines.each { |line| puts "  #{line.rstrip}" }
              elsif options[:stat]
                puts "[#{repo_name}] Diffstat:"
                output.lines.each { |line| puts "  #{line.rstrip}" }
              else
                puts "[#{repo_name}] Differences:"
                puts output
              end
              puts "" # Add spacing between repositories
            end

            unless has_changes
              puts "No changes found across repositories"
            end
          end

          def display_diff_errors(result, options)
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
                puts "Partial success: Diff shown for repositories: #{successful_names}"
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
