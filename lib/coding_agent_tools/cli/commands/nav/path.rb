# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Nav
        class Path < Dry::CLI::Command
          desc "Intelligent path resolution and generation"

          argument :type, desc: "Path operation type: task-new, task, docs-new, reflection-new, file"
          argument :input, desc: "Input for path resolution (title for new paths, ID/pattern for existing paths)"

          option :title, desc: "Title for new path generation (alternative to input argument)"

          def call(type:, input: nil, **options)
            # Initialize components
            path_resolver = CodingAgentTools::Molecules::PathResolver.new
            
            # Get input from title option if not provided as argument
            actual_input = input || options[:title]
            
            
            if actual_input.nil? || actual_input.strip.empty?
              puts "Error: Input required for path resolution"
              puts "Usage: nav path TYPE INPUT [OPTIONS]"
              puts "       nav path TYPE --title 'Title'"
              return
            end

            # Determine path type
            path_type = case type
            when "task-new", "task_new"
              :task_new
            when "docs-new", "docs_new"
              :docs_new
            when "reflection-new", "reflection_new"
              :reflection_new
            when "task"
              :task
            when "file"
              :file
            else
              puts "Error: Unknown path type '#{type}'"
              puts "Valid types: task-new, task, docs-new, reflection-new, file"
              return
            end

            # Resolve the path
            result = path_resolver.resolve_path(actual_input, type: path_type)

            if result[:success]
              case result[:type]
              when :single
                puts result[:path]
              when :multiple
                puts "Multiple matches found:"
                result[:paths].each_with_index do |path, index|
                  puts "#{index + 1}) #{path}"
                end
              end
            else
              puts "Error: #{result[:error]}"
            end
          rescue StandardError => e
            puts "Error: #{e.message}"
          end
        end
      end
    end
  end
end