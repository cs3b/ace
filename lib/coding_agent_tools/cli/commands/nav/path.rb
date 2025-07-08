# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Nav
        class Path < Dry::CLI::Command
          desc "Intelligent path resolution and generation"

          argument :type, desc: "Path operation type: task-new, task, docs-new, reflection-new, reflection-list, file"
          argument :input, desc: "Input for path resolution (title for new paths, ID/pattern for existing paths)"

          option :title, desc: "Title for new path generation (alternative to input argument)"

          def call(type:, input: nil, **options)
            # Initialize components
            path_resolver = CodingAgentTools::Molecules::PathResolver.new

            # Get input from title option if not provided as argument
            actual_input = input || options[:title]

            # reflection-list doesn't need input
            unless type == "reflection-list" || type == "reflection_list"
              if actual_input.nil? || actual_input.strip.empty?
                puts "Error: Input required for path resolution"
                puts "Usage: nav path TYPE INPUT [OPTIONS]"
                puts "       nav path TYPE --title 'Title'"
                return
              end
            end

            # Determine path type
            path_type = case type
            when "task-new", "task_new"
              :task_new
            when "docs-new", "docs_new"
              :docs_new
            when "reflection-new", "reflection_new"
              :reflection_new
            when "reflection-list", "reflection_list"
              :reflection_list
            when "task"
              :task
            when "file"
              :file
            else
              puts "Error: Unknown path type '#{type}'"
              puts "Valid types: task-new, task, docs-new, reflection-new, reflection-list, file"
              return
            end

            # Resolve the path
            result = if path_type == :reflection_list
              path_resolver.find_reflection_paths_in_current_release
            else
              path_resolver.resolve_path(actual_input, type: path_type)
            end

            if result[:success]
              case result[:type]
              when :single
                # Standard single result
                if result[:autocorrect_message]
                  puts result[:autocorrect_message]
                end
                puts result[:path]
              when :list
                # Reflection list - output each path on separate line
                result[:paths].each { |path| puts path }
              when :multiple
                # Use smart prioritization for multiple matches
                prioritized = path_resolver.prioritize_matches(result[:paths])
                puts "Autocorrected: '#{actual_input}' → '#{prioritized[:best]}'"
                puts prioritized[:best]

                # Show alternatives if any exist
                unless prioritized[:alternatives].empty?
                  puts path_resolver.format_alternative_matches(prioritized[:alternatives])
                end
              when :scoped_multiple
                # Scoped pattern with multiple matches
                if result[:autocorrect_message]
                  puts result[:autocorrect_message]
                end
                puts result[:path]

                # Show scoped alternatives if any exist
                if result[:alternative_message] && !result[:alternative_message].empty?
                  puts result[:alternative_message]
                end
              end
            else
              puts "Error: #{result[:error]}"
            end
          rescue => e
            puts "Error: #{e.message}"
          end
        end
      end
    end
  end
end
