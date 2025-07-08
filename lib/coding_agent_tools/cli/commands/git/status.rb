# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Status < Dry::CLI::Command
          desc "Show status across all repositories with clear prefixes"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :porcelain, type: :boolean, default: false,
            desc: "Give the output in porcelain format"

          option :short, type: :boolean, default: false, aliases: ["s"],
            desc: "Give the output in short format"

          option :verbose, type: :boolean, default: false, aliases: ["v"],
            desc: "Show detailed status information"

          option :untracked_files, type: :string, default: "normal",
            desc: "Show untracked files (no|normal|all)"

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
            "--short",
            "--verbose",
            "--porcelain",
            "--repository dev-tools",
            "--main-only",
            "--submodules-only",
            "--no-color",
            "--force-color"
          ]

          def call(**options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build status options for git command
            status_options = build_status_options(options)

            # Execute status across repositories
            result = orchestrator.status(status_options)

            if result[:success]
              display_status_output(result, options)
              0
            else
              display_errors(result[:errors], options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_status_options(options)
            status_opts = {}

            # Repository filtering
            status_opts[:repository] = options[:repository] if options[:repository]
            status_opts[:main_only] = options[:main_only] if options[:main_only]
            status_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Git status specific options
            status_opts[:porcelain] = options[:porcelain] if options[:porcelain]
            status_opts[:short] = options[:short] if options[:short]
            status_opts[:verbose] = options[:verbose] if options[:verbose]
            status_opts[:untracked_files] = options[:untracked_files] if options[:untracked_files] != "normal"

            # Color options
            status_opts[:no_color] = options[:no_color] if options[:no_color]
            status_opts[:force_color] = options[:force_color] if options[:force_color]

            status_opts
          end

          def display_status_output(result, options)
            if options[:porcelain]
              display_porcelain_output(result)
            elsif result[:formatted_output]
              puts result[:formatted_output]
            else
              display_raw_output(result)
            end
          end

          def display_porcelain_output(result)
            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              output.lines.each do |line|
                next if line.strip.empty?
                puts "#{repo_name}:#{line.rstrip}"
              end
            end
          end

          def display_raw_output(result)
            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              if output.strip.empty?
                puts "[#{repo_name}] Clean working directory"
              else
                puts "[#{repo_name}] Status:"
                output.lines.each { |line| puts "  #{line.rstrip}" }
              end
              puts "" # Add spacing between repositories
            end
          end

          def display_errors(errors, options)
            errors.each do |error_info|
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
