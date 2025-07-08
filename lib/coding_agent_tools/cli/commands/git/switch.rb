# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Switch < Dry::CLI::Command
          desc "Switch branches across all repositories"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :quiet, type: :boolean, default: false, aliases: ["q"],
            desc: "Quiet operation, suppress feedback messages"

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Force switch, throw away local changes"

          option :merge, type: :boolean, default: false, aliases: ["m"],
            desc: "3-way merge between current branch, working tree, and new branch"

          option :detach, type: :boolean, default: false,
            desc: "Switch to a commit for inspection and discardable experiments"

          option :create, type: :string, aliases: ["c"],
            desc: "Create a new branch and switch to it"

          option :force_create, type: :string, aliases: ["C"],
            desc: "Create/reset and switch to a branch"

          option :orphan, type: :string,
            desc: "Create a new orphan branch and switch to it"

          option :guess, type: :boolean, default: true,
            desc: "Try to find a tracking branch (default: true)"

          option :no_guess, type: :boolean, default: false,
            desc: "Do not try to find a tracking branch"

          option :track, type: :boolean, default: false, aliases: ["t"],
            desc: "Set up tracking relationship"

          option :no_track, type: :boolean, default: false,
            desc: "Do not set up tracking relationship"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          option :concurrent, type: :boolean, default: false,
            desc: "Execute switch operations concurrently across repositories"

          argument :branch, type: :string, required: false,
            desc: "Branch name to switch to"

          example [
            "main",
            "feature-branch",
            "--create new-feature",
            "--force-create hotfix main",
            "--detach HEAD~1",
            "--orphan empty-branch",
            "--no-guess feature-branch",
            "--track origin/feature"
          ]

          def call(branch: nil, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build switch options
            switch_options = build_switch_options(branch, options)

            # Execute switch across repositories
            result = orchestrator.switch(branch, switch_options)

            if result[:success]
              display_switch_success(result, options)
              0
            else
              display_switch_errors(result, options)
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def build_switch_options(branch, options)
            switch_opts = {
              capture_output: true
            }

            # Repository filtering
            switch_opts[:repository] = options[:repository] if options[:repository]
            switch_opts[:main_only] = options[:main_only] if options[:main_only]
            switch_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Switch behavior
            switch_opts[:quiet] = options[:quiet] if options[:quiet]
            switch_opts[:force] = options[:force] if options[:force]
            switch_opts[:merge] = options[:merge] if options[:merge]
            switch_opts[:detach] = options[:detach] if options[:detach]
            switch_opts[:create] = options[:create] if options[:create]
            switch_opts[:force_create] = options[:force_create] if options[:force_create]
            switch_opts[:orphan] = options[:orphan] if options[:orphan]
            switch_opts[:guess] = options[:guess] unless options[:no_guess]
            switch_opts[:no_guess] = options[:no_guess] if options[:no_guess]
            switch_opts[:track] = options[:track] if options[:track]
            switch_opts[:no_track] = options[:no_track] if options[:no_track]
            switch_opts[:concurrent] = options[:concurrent] if options[:concurrent]

            switch_opts
          end

          def display_switch_success(result, options)
            result[:results]&.each do |repo_name, repo_result|
              next unless repo_result[:success]

              if repo_result[:commands]
                # Multiple commands (from concurrent execution)
                repo_result[:commands].each do |cmd_result|
                  display_single_switch_result(repo_name, cmd_result, options)
                end
              else
                # Single command result
                display_single_switch_result(repo_name, repo_result, options)
              end
            end

            if result[:repositories_processed]
              repos_list = result[:repositories_processed].join(", ")
              puts "Switch completed across repositories: #{repos_list}" unless options[:quiet]
            end
          end

          def display_single_switch_result(repo_name, result, options)
            return if options[:quiet]

            if result[:success]
              if result[:stdout] && !result[:stdout].strip.empty?
                puts "[#{repo_name}] #{result[:stdout].strip}"
              elsif result[:output] && !result[:output].strip.empty?
                puts "[#{repo_name}] #{result[:output].strip}"
              else
                puts "[#{repo_name}] Switch completed successfully"
              end
            else
              error_message = result[:error] || result[:stderr] || "Switch operation failed"
              error_output("[#{repo_name}] #{error_message}")
            end
          end

          def display_switch_errors(result, options)
            if result[:error]
              # Single error (e.g., from orchestrator)
              error_output("Switch failed: #{result[:error]}")
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
                puts "Partial success: Switch completed in repositories: #{successful_names}"
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
