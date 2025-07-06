# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/release_manager"
require_relative "../../../atoms/project_root_detector"

module CodingAgentTools
  module Cli
    module Commands
      module Release
        # GenerateId command for generating next available task ID
        class GenerateId < Dry::CLI::Command
          desc "Generate next available task ID with minor version bump"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :count, type: :integer, default: 1,
            desc: "Number of task IDs to generate (default: 1)"

          example [
            "",
            "--count 3",
            "--format json",
            "--debug"
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            release_manager = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: project_root)

            count = validate_count(options[:count]) if options[:count]
            count ||= options[:count] || 1

            if count == 1
              # Single ID generation
              result = release_manager.generate_id
              handle_single_result(result, options)
            else
              # Multiple ID generation
              handle_multiple_generation(release_manager, count, options)
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def validate_count(count)
            count_int = count.to_i
            unless count_int.positive?
              raise ArgumentError, "Count must be a positive integer, got: #{count}"
            end
            count_int
          end

          def handle_single_result(result, options)
            if options[:format] == "json"
              handle_json_single_result(result)
            else
              handle_text_single_result(result)
            end

            result.success? ? 0 : 1
          end

          def handle_multiple_generation(release_manager, count, options)
            task_ids = []
            base_result = release_manager.generate_id

            unless base_result.success?
              if options[:format] == "json"
                handle_json_single_result(base_result)
              else
                handle_text_single_result(base_result)
              end
              return 1
            end

            # Generate sequential task IDs
            base_id = base_result.data
            version = extract_version_from_id(base_id)
            base_number = extract_task_number_from_id(base_id)

            count.times do |i|
              task_ids << "#{version}+task.#{base_number + i}"
            end

            if options[:format] == "json"
              handle_json_multiple_result(task_ids)
            else
              handle_text_multiple_result(task_ids)
            end

            0
          end

          def handle_text_single_result(result)
            unless result.success?
              error_output("Error: #{result.error_message}")
              return
            end

            puts result.data
          end

          def handle_text_multiple_result(task_ids)
            puts "Generated #{task_ids.length} task IDs:"
            task_ids.each do |id|
              puts "  #{id}"
            end
          end

          def handle_json_single_result(result)
            require "json"

            output = if result.success?
              {
                success: true,
                data: result.data
              }
            else
              {
                success: false,
                error: result.error_message
              }
            end

            puts JSON.pretty_generate(output)
          end

          def handle_json_multiple_result(task_ids)
            require "json"

            output = {
              success: true,
              data: task_ids,
              count: task_ids.length
            }

            puts JSON.pretty_generate(output)
          end

          def extract_version_from_id(task_id)
            match = task_id.match(/^(v\.\d+\.\d+\.\d+)\+task\./)
            match ? match[1] : "v.0.1.0"
          end

          def extract_task_number_from_id(task_id)
            match = task_id.match(/\+task\.(\d+)$/)
            match ? match[1].to_i : 1
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
