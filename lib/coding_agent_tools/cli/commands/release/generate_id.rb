# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/taskflow_management/release_manager'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # GenerateId command for creating next release directory with codename
        class GenerateId < Dry::CLI::Command
          desc 'Create next release directory with codename'

          option :codename, type: :string,
            desc: "Codename for the release (e.g., 'whisty'). If not provided, generates unique codename using LLM"

          option :debug, type: :boolean, default: false, aliases: ['d'],
            desc: 'Enable debug output for verbose error information'

          option :format, type: :string, default: 'text', values: ['text', 'json'],
            desc: 'Output format (text or json)'

          example [
            '',
            '--codename whisty',
            '--format json',
            '--debug'
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: project_root)

            # Generate release with optional codename
            result = release_manager.generate_release(codename: options[:codename])
            handle_result(result, options)
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def handle_result(result, options)
            if options[:format] == 'json'
              handle_json_result(result)
            else
              handle_text_result(result)
            end

            result.success? ? 0 : 1
          end

          def handle_text_result(result)
            unless result.success?
              error_output("Error: #{result.error_message}")
              return
            end

            data = result.data
            puts "version: #{data[:version]}"
            puts "path: #{data[:path]}"
          end

          def handle_json_result(result)
            require 'json'

            output = if result.success?
              {
                success: true,
                version: result.data[:version],
                codename: result.data[:codename],
                path: result.data[:path]
              }
            else
              {
                success: false,
                error: result.error_message
              }
            end

            puts JSON.pretty_generate(output)
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output('Use --debug flag for more information')
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
