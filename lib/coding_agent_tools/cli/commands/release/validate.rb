# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/taskflow_management/release_manager'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # Validate command for checking release context consistency
        class Validate < Dry::CLI::Command
          desc 'Validate release context consistency between tools'

          option :debug, type: :boolean, default: false, aliases: ['d'],
            desc: 'Enable debug output for verbose error information'

          option :format, type: :string, default: 'text', values: ['text', 'json'],
            desc: 'Output format (text or json)'

          example [
            '',
            '--format json',
            '--debug'
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: project_root)

            result = release_manager.validate_release_context_consistency

            if options[:format] == 'json'
              handle_json_result(result)
            else
              handle_text_result(result)
            end

            result.success? ? 0 : 1
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def handle_text_result(result)
            if result.success?
              validation_data = result.data
              puts 'Release Context Validation: PASSED'
              puts '=' * 40
              puts "  Current Release: #{validation_data[:current_release]}"
              puts "  Path: #{validation_data[:path]}"
              puts "  Status: #{validation_data[:validation_status]}"
              puts ''
              puts '✓ No inconsistencies detected between release-manager and nav-path'
            else
              error_output("Validation FAILED: #{result.error_message}")
              puts ''
              puts 'This indicates that release-manager and nav-path may report different'
              puts 'current releases, which could cause task creation inconsistencies.'
              puts ''
              puts 'Recommended actions:'
              puts '1. Check that dev-taskflow/current/ contains exactly one release directory'
              puts '2. Verify that both tools use the same release detection mechanism'
              puts '3. Check for any manual modifications to release directories'
            end
          end

          def handle_json_result(result)
            require 'json'

            output = if result.success?
              {
                success: true,
                validation_status: 'passed',
                data: result.data,
                message: result.error_message || 'Validation passed'
              }
            else
              {
                success: false,
                validation_status: 'failed',
                error: result.error_message,
                recommendations: [
                  'Check that dev-taskflow/current/ contains exactly one release directory',
                  'Verify that both tools use the same release detection mechanism',
                  'Check for any manual modifications to release directories'
                ]
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
