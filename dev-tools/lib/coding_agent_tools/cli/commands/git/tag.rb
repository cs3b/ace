# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/git/git_orchestrator"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Git
        class Tag < Dry::CLI::Command
          desc "Create, delete, list or verify tags across all repositories"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :repository, type: :string, aliases: ["C"],
            desc: "Specify explicit repository context (e.g., 'dev-tools')"

          option :annotate, type: :boolean, default: false, aliases: ["a"],
            desc: "Make an unsigned, annotated tag object"

          option :sign, type: :boolean, default: false, aliases: ["s"],
            desc: "Make a GPG-signed tag"

          option :local_user, type: :string, aliases: ["u"],
            desc: "Make a GPG-signed tag, using the given key"

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Replace an existing tag with the given name"

          option :delete, type: :boolean, default: false, aliases: ["d"],
            desc: "Delete existing tags with the given names"

          option :verify, type: :boolean, default: false, aliases: ["v"],
            desc: "Verify the GPG signature of the given tag names"

          option :list, type: :boolean, default: false, aliases: ["l"],
            desc: "List tags"

          option :message, type: :string, aliases: ["m"],
            desc: "Use the given tag message"

          option :file, type: :string, aliases: ["F"],
            desc: "Take the tag message from the given file"

          option :main_only, type: :boolean, default: false,
            desc: "Process main repository only"

          option :submodules_only, type: :boolean, default: false,
            desc: "Process submodules only"

          argument :tagname, required: false, desc: "The name of the tag to create, delete, or describe"
          argument :commit, required: false, desc: "The object that the new tag will refer to (defaults to HEAD)"

          example [
            "v1.2.3",
            "-a v1.2.3 -m 'Release version 1.2.3'",
            "-d v1.2.3",
            "-l",
            "-f v1.2.3"
          ]

          def call(tagname: nil, commit: nil, **options)
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            orchestrator = CodingAgentTools::Organisms::Git::GitOrchestrator.new(project_root, options)

            # Build tag options for git command
            tag_options = build_tag_options(options)

            # Execute tag operation across repositories
            result = orchestrator.tag(tagname, commit, tag_options)

            if result[:success]
              display_tag_output(result, options)
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

          def build_tag_options(options)
            tag_opts = {}

            # Repository filtering
            tag_opts[:repository] = options[:repository] if options[:repository]
            tag_opts[:main_only] = options[:main_only] if options[:main_only]
            tag_opts[:submodules_only] = options[:submodules_only] if options[:submodules_only]

            # Git tag specific options
            tag_opts[:annotate] = options[:annotate] if options[:annotate]
            tag_opts[:sign] = options[:sign] if options[:sign]
            tag_opts[:local_user] = options[:local_user] if options[:local_user]
            tag_opts[:force] = options[:force] if options[:force]
            tag_opts[:delete] = options[:delete] if options[:delete]
            tag_opts[:verify] = options[:verify] if options[:verify]
            tag_opts[:list] = options[:list] if options[:list]
            tag_opts[:message] = options[:message] if options[:message]
            tag_opts[:file] = options[:file] if options[:file]

            tag_opts
          end

          def display_tag_output(result, _options)
            if result[:formatted_output]
              puts result[:formatted_output]
            else
              display_raw_output(result)
            end
          end

          def display_raw_output(result)
            result[:results].each do |repo_name, repo_result|
              next unless repo_result[:success]

              output = repo_result[:stdout] || ""
              if output.strip.empty?
                puts "[#{repo_name}] Clean working directory"
              else
                puts "[#{repo_name}] Output:"
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

            return if options[:debug]

            error_output("Use --debug flag for more information")
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
