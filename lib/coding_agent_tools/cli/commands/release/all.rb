# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/release_manager"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # All command for listing all releases across done/current/backlog
        class All < Dry::CLI::Command
          desc "List all releases across done/current/backlog with metadata"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :type, type: :string, values: %w[done current backlog],
            desc: "Filter by release type (done, current, or backlog)"

          option :limit, type: :integer,
            desc: "Maximum number of releases to show"

          example [
            "",
            "--type current",
            "--format json",
            "--limit 5",
            "--debug"
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: project_root)

            result = release_manager.all

            unless result.success?
              if options[:format] == "json"
                handle_json_error(result)
              else
                error_output("Error: #{result.error_message}")
              end
              return 1
            end

            releases = filter_releases(result.data, options)

            if options[:format] == "json"
              handle_json_result(releases)
            else
              handle_text_result(releases, options)
            end

            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def filter_releases(releases, options)
            # Filter by type if specified
            if options[:type]
              type_symbol = options[:type].to_sym
              releases = releases.select { |release| release.type == type_symbol }
            end

            # Apply limit if specified
            if options[:limit]
              limit = options[:limit].to_i
              releases = releases.take(limit)
            end

            releases
          end

          def handle_text_result(releases, options)
            if releases.empty?
              puts "No releases found"
              return
            end

            total_count = releases.length
            type_filter = options[:type] ? " (#{options[:type]})" : ""

            puts "All Releases#{type_filter} (#{total_count} total):"
            puts "=" * 60

            releases.each_with_index do |release, index|
              puts "" if index > 0  # Add blank line between releases
              display_release_info(release, index + 1)
            end

            # Summary
            puts
            puts "Summary:"
            puts "  Total releases: #{total_count}"

            type_counts = releases.group_by(&:type).transform_values(&:count)
            type_counts.each do |type, count|
              puts "  #{type.to_s.capitalize}: #{count}"
            end

            total_tasks = releases.sum(&:task_count)
            puts "  Total tasks: #{total_tasks}"
          end

          def display_release_info(release, position)
            status_display = colorize_status(release.status)
            type_display = colorize_type(release.type)

            puts "#{position.to_s.rjust(3)}. #{release.name}"
            puts "     Version: #{release.version}"
            puts "     Type: #{type_display}"
            puts "     Status: #{status_display}"
            puts "     Path: #{release.path}"
            puts "     Tasks: #{release.task_count}"

            if release.created_at
              puts "     Created: #{format_time(release.created_at)}"
            end

            if release.modified_at
              puts "     Modified: #{format_time(release.modified_at)}"
            end
          end

          def handle_json_result(releases)
            require "json"

            data = releases.map do |release|
              {
                name: release.name,
                version: release.version,
                path: release.path,
                type: release.type.to_s,
                status: release.status,
                task_count: release.task_count,
                created_at: release.created_at&.iso8601,
                modified_at: release.modified_at&.iso8601
              }
            end

            output = {
              success: true,
              data: data,
              count: releases.length,
              summary: {
                total_releases: releases.length,
                total_tasks: releases.sum(&:task_count),
                by_type: releases.group_by(&:type).transform_values(&:count).transform_keys(&:to_s)
              }
            }

            puts JSON.pretty_generate(output)
          end

          def handle_json_error(result)
            require "json"

            output = {
              success: false,
              error: result.error_message
            }

            puts JSON.pretty_generate(output)
          end

          def colorize_status(status)
            case status
            when "active"
              colorize(status.upcase, :blue)
            when "archived"
              colorize(status.upcase, :green)
            when "planned"
              colorize(status.upcase, :yellow)
            else
              status.upcase
            end
          end

          def colorize_type(type)
            case type
            when :current
              colorize(type.to_s.upcase, :blue)
            when :done
              colorize(type.to_s.upcase, :green)
            when :backlog
              colorize(type.to_s.upcase, :yellow)
            else
              type.to_s.upcase
            end
          end

          def colorize(text, color)
            case color
            when :red
              "\e[31m#{text}\e[0m"
            when :green
              "\e[32m#{text}\e[0m"
            when :yellow
              "\e[33m#{text}\e[0m"
            when :blue
              "\e[34m#{text}\e[0m"
            else
              text
            end
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
