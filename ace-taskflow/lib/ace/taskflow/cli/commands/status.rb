# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/taskflow_context_loader"
require_relative "../../molecules/task_display_formatter"
require_relative "../../atoms/task_reference_parser"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the status command
        #
        # This command shows taskflow status and activity.
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Show current taskflow status and activity

            SYNTAX:
              ace-taskflow status [OPTIONS]

            EXAMPLES:

              # Show status
              $ ace-taskflow status
              $ ace-taskflow context

              # JSON output
              $ ace-taskflow status --json

            CONFIGURATION:

              Global config:  ~/.ace/taskflow/config.yml
              Project config: .ace/taskflow/config.yml
              Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

            OUTPUT:

              Shows: Release info, current task, task activity
              Exit codes: 0 (success), 1 (error)
          DESC

          example [
            '                 # Show status',
            '--json           # JSON output'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"
          option :json, type: :boolean, desc: "Output as JSON"
          option :markdown, type: :boolean, desc: "Output as Markdown (default)"
          option :recently_done_limit, type: :integer, desc: "Max recently done tasks to show"
          option :up_next_limit, type: :integer, desc: "Max up next tasks to show"
          option :include_drafts, type: :boolean, desc: "Include draft tasks in Up Next"
          option :include_activity, type: :boolean, desc: "Include task activity section (default: true)"

          def call(**options)
            clean_options = options.reject { |k, _| k == :args }

            # Convert numeric options from strings to integers using Base helper
            convert_types(clean_options,
                          recently_done_limit: :integer,
                          up_next_limit: :integer)

            execute_status(clean_options)
          end

          private

          def execute_status(options)
            # Determine output format from dry-cli options
            format = options[:json] ? "json" : "markdown"

            # Build loader options from CLI flags
            loader_options = {}
            loader_options[:recently_done_limit] = options[:recently_done_limit] if options.key?(:recently_done_limit)
            loader_options[:up_next_limit] = options[:up_next_limit] if options.key?(:up_next_limit)
            loader_options[:include_drafts] = options[:include_drafts] if options.key?(:include_drafts)

            # Load context with activity options
            context = Organisms::TaskflowContextLoader.load(loader_options)

            # Format and output
            display_options = loader_options.merge(
              include_activity: options.fetch(:include_activity, true)
            )

            case format
            when "json"
              output_json(context, display_options)
            else
              output_markdown(context, display_options)
            end

          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def output_json(context, display_options = {})
            require "json"
            json_context = serialize_context_for_json(context)
            json_context.delete(:task_activity) if display_options[:include_activity] == false
            puts JSON.pretty_generate(json_context)
          end

          def serialize_context_for_json(context)
            deep_serialize(context)
          end

          def deep_serialize(value)
            case value
            when Hash
              value.transform_values { |v| deep_serialize(v) }
            when Array
              value.map { |v| deep_serialize(v) }
            else
              value
            end
          end

          def output_markdown(context, display_options = {})
            puts "# Taskflow Status"
            puts ""

            output_task_section(context[:task], context[:release])

            if context[:task_activity] && display_options[:include_activity] != false
              puts ""
              output_activity_section(context[:task_activity], display_options)
            end
          end

          def output_activity_section(activity, loader_options = {})
            format_options = {
              skip_recently_done: loader_options[:recently_done_limit] == 0,
              skip_up_next: loader_options[:up_next_limit] == 0
            }
            formatted = Molecules::TaskDisplayFormatter.format_activity_section(activity, format_options)
            puts formatted unless formatted.empty?
          end

          def output_task_section(task, release = nil)
            if release
              puts "## Release: #{format_release_header(release)}"
              puts ""
            end

            if task.nil?
              puts "No task pattern detected in branch name."
              puts ""
              return
            end

            status_icon = status_icon_for(task[:status])

            puts "## Task: #{task[:id]} [#{status_icon}] #{task[:title]}"

            path = format_relative_path(task[:path])
            puts "  Path: #{path}"
            puts ""

            task_ref = task[:parent] || extract_task_number(task[:id])
            if task_ref
              puts "### Parent Task" if task[:parent]
              show_task_details_from_command(task_ref)
            else
              puts "  Error: Invalid task reference (malformed task ID)"
            end
          end

          def status_icon_for(status)
            Molecules::TaskDisplayFormatter.status_icon(status)
          end

          def extract_task_number(id)
            Atoms::TaskReferenceParser.extract_number(id)
          end

          def format_relative_path(path)
            return path unless path

            project_root = ENV["PROJECT_ROOT_PATH"]
            return path unless project_root

            require "pathname"
            path_obj = Pathname.new(path)
            root_obj = Pathname.new(project_root)

            begin
              path_obj.relative_path_from(root_obj).to_s
            rescue ArgumentError
              path
            end
          end

          def format_release_header(release)
            name = release[:name]
            done = release[:done_tasks] || 0
            total = release[:total_tasks] || 0
            codename = release[:codename]

            header = "#{name}: #{done}/#{total} tasks done"
            header += " • #{codename}" if codename && !codename.empty?
            header
          end

          def show_task_details_from_command(task_ref)
            output = fetch_task_output(task_ref)
            if output.empty?
              return false
            end
            output.each_line do |line|
              puts "  #{line}"
            end
            true
          end

          def fetch_task_output(task_ref)
            require "stringio"

            original_stdout = $stdout
            output = StringIO.new
            $stdout = output

            begin
              # Use the Task CLI command to display task details
              task_cmd = Task.new
              task_cmd.call(args: [task_ref.to_s], quiet: true)
            rescue StandardError => e
              # Log errors for debugging
              if defined?(Ace::Core) && Ace::Core.respond_to?(:logger)
                Ace::Core.logger.debug("[Status] Task lookup error: #{e.message}")
              elsif ENV["DEBUG"]
                $stderr.puts "[Status] Task lookup error: #{e.message}"
              end
            ensure
              $stdout = original_stdout
            end

            output.string
          end
        end
      end
    end
  end
end
