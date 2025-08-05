# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/taskflow_management/release_manager'
require_relative '../../../atoms/project_root_detector'

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # Next command for finding next available release in backlog
        class Next < Dry::CLI::Command
          desc 'Find next available release in backlog'

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

            result = release_manager.next

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
            unless result.success?
              error_output("Error: #{result.error_message}")
              return
            end

            if result.data.nil?
              puts result.error_message || 'No next release available'
              return
            end

            release = result.data
            puts 'Next Release Available:'
            puts '=' * 30
            puts "  Name:      #{release.name}"
            puts "  Version:   #{release.version}"
            puts "  Path:      #{release.path}"
            puts "  Status:    #{release.status}"
            puts "  Tasks:     #{release.task_count}"

            puts "  Created:   #{format_time(release.created_at)}" if release.created_at

            return unless release.modified_at

            puts "  Modified:  #{format_time(release.modified_at)}"
          end

          def handle_json_result(result)
            require 'json'

            if result.success?
              if result.data
                release = result.data
                output = {
                  success: true,
                  data: {
                    name: release.name,
                    version: release.version,
                    path: release.path,
                    type: release.type.to_s,
                    status: release.status,
                    task_count: release.task_count,
                    created_at: release.created_at&.iso8601,
                    modified_at: release.modified_at&.iso8601
                  }
                }
              else
                output = {
                  success: true,
                  data: nil,
                  message: result.error_message || 'No next release available'
                }
              end
            else
              output = {
                success: false,
                error: result.error_message
              }
            end

            puts JSON.pretty_generate(output)
          end

          def format_time(time)
            time.strftime('%Y-%m-%d %H:%M:%S')
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
