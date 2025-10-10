# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/release_manager"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # Current command for getting current release information
        class Current < Dry::CLI::Command
          desc "Get current release information"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :format, type: :string, default: "text", values: ["text", "json"],
            desc: "Output format (text or json)"

          option :path, type: :string,
            desc: "Resolve path within current release"

          example [
            "",
            "--format json",
            "--debug",
            "--path reflections",
            "--path reflections/synthesis --format json"
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: project_root)

            # Handle --path option
            if options[:path]
              handle_path_resolution(release_manager, options[:path], options[:format])
              return 0
            end

            result = release_manager.current

            if options[:format] == "json"
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

          def handle_path_resolution(release_manager, subpath, format)
            resolved_path = release_manager.resolve_path(subpath)

            if format == "json"
              handle_path_json_result(resolved_path, subpath)
            else
              handle_path_text_result(resolved_path)
            end
          rescue => e
            if format == "json"
              handle_path_json_error(e, subpath)
            else
              error_output("Error resolving path '#{subpath}': #{e.message}")
            end
            raise e
          end

          def handle_path_text_result(resolved_path)
            puts resolved_path
          end

          def handle_path_json_result(resolved_path, subpath)
            require "json"

            output = {
              success: true,
              data: {
                subpath: subpath,
                resolved_path: resolved_path,
                exists: File.exist?(resolved_path)
              }
            }
            puts JSON.pretty_generate(output)
          end

          def handle_path_json_error(error, subpath)
            require "json"

            output = {
              success: false,
              error: error.message,
              data: {
                subpath: subpath
              }
            }
            puts JSON.pretty_generate(output)
          end

          def handle_text_result(result)
            unless result.success?
              error_output("Error: #{result.error_message}")
              return
            end

            release = result.data
            puts "Current Release Information:"
            puts "=" * 40
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
            require "json"

            if result.success?
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
                success: false,
                error: result.error_message
              }
            end

            puts JSON.pretty_generate(output)
          end

          def format_time(time)
            time.strftime("%Y-%m-%d %H:%M:%S")
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
