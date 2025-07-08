# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Log < Dry::CLI::Command
          desc "Show commit logs across repositories with repository names per commit"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :oneline, type: :boolean, default: false,
            desc: "Show commits in oneline format"

          option :graph, type: :boolean, default: false,
            desc: "Show commit graph"

          option :since, type: :string,
            desc: "Show commits since date (e.g., '2 weeks ago')"

          option :until, type: :string,
            desc: "Show commits until date"

          option :author, type: :string,
            desc: "Show commits by specific author"

          option :grep, type: :string,
            desc: "Search commit messages"

          option :max_count, type: :integer, aliases: ["n"],
            desc: "Maximum number of commits to show"

          option :separated, type: :boolean, default: false,
            desc: "Show commits grouped by repository (default: show repository with each commit)"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          option :no_color, type: :boolean, default: false,
            desc: "Disable colored output"

          option :force_color, type: :boolean, default: true,
            desc: "Force colored output even when not on TTY (default: true)"

          example [
            "",
            "--oneline -n 10",
            "--graph --since '1 week ago'",
            "--author 'John Doe'",
            "--grep 'fix bug'",
            "--separated",
            "--repository dev-tools",
            "--no-color",
            "--force-color"
          ]

          def call(**options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build log options
            log_options = build_log_options(options)

            # Execute log across repositories
            result = orchestrator.log(log_options)

            if result[:success]
              display_log_output(result, options)
              0
            else
              display_log_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_log_options(options)
            log_opts = {
              capture_output: true
            }

            # Repository filtering
            log_opts[:repository] = options[:repository] if options[:repository]
            log_opts[:main_only] = options[:main_only] if options[:main_only]
            log_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Git log specific options
            log_opts[:oneline] = options[:oneline] if options[:oneline]
            log_opts[:graph] = options[:graph] if options[:graph]
            log_opts[:since] = options[:since] if options[:since]
            log_opts[:until] = options[:until] if options[:until]
            log_opts[:author] = options[:author] if options[:author]
            log_opts[:grep] = options[:grep] if options[:grep]
            log_opts[:max_count] = options[:max_count] if options[:max_count]
            log_opts[:separated] = options[:separated] if options[:separated]

            # Color options
            log_opts[:no_color] = options[:no_color] if options[:no_color]
            log_opts[:force_color] = options[:force_color] if options[:force_color]

            log_opts
          end

          def display_log_output(result, options)
            if result[:formatted_output]
              puts result[:formatted_output]
            else
              display_raw_log_output(result, options)
            end
          end

          def display_raw_log_output(result, options)
            if options[:separated]
              display_separated_log(result)
            else
              display_unified_log(result)
            end
          end

          def display_unified_log(result)
            all_commits = []

            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              output.lines.each do |line|
                next if line.strip.empty?
                all_commits << {repo: repo_name, line: line.rstrip}
              end
            end

            # For now, just group by repository (sorting by date would require parsing)
            all_commits.each do |commit|
              puts "[#{commit[:repo]}] #{commit[:line]}"
            end
          end

          def display_separated_log(result)
            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              next if output.strip.empty?

              puts "[#{repo_name}] Recent commits:"
              output.lines.each { |line| puts "  #{line.rstrip}" }
              puts "" # Add spacing between repositories
            end
          end

          def display_log_errors(result, options)
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
                puts "Partial success: Log shown for repositories: #{successful_names}"
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
