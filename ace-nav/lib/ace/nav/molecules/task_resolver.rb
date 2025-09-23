# frozen_string_literal: true

require "pathname"
require_relative "config_loader"

module Ace
  module Nav
    module Molecules
      # Resolves task:// URIs to task files
      class TaskResolver
        def initialize(config_loader: nil)
          @base_path = find_project_root
          @config_loader = config_loader || ConfigLoader.new
          @config = @config_loader.load_protocol_config("task")
        end

        def resolve(task_identifier)
          # Normalize task identifier (018 or v.0.9.0+task.018)
          task_number = extract_task_number(task_identifier)
          return nil unless task_number

          # Get search paths from configuration
          search_paths = @config["search_paths"] || default_search_paths

          # Build patterns for each search path
          patterns = search_paths.flat_map do |search_path|
            [
              "#{search_path}/*task.#{task_number}*.md",
              "#{search_path}/task.#{task_number}/*.md"
            ]
          end

          patterns.each do |pattern|
            files = Dir.glob(File.join(@base_path, pattern))
            return files.first unless files.empty?
          end

          nil
        end

        def list_tasks(pattern = "*")
          task_pattern = pattern == "*" ? "*" : "*#{pattern}*"

          # Get search paths from configuration
          search_paths = @config["search_paths"] || default_search_paths

          # Build patterns for each search path
          patterns = search_paths.flat_map do |search_path|
            [
              "#{search_path}/#{task_pattern}.md",
              "#{search_path}/task.*/#{task_pattern}.md"
            ]
          end

          tasks = []
          patterns.each do |pat|
            files = Dir.glob(File.join(@base_path, pat))
            tasks.concat(files)
          end

          tasks.uniq.sort
        end

        private

        def find_project_root
          # Start from current directory and search upward
          current = Pathname.pwd

          while current.parent != current
            # Check for indicators of project root
            if File.exist?(File.join(current, "dev-taskflow")) ||
               File.exist?(File.join(current, ".ace")) ||
               File.exist?(File.join(current, ".git"))
              return current.to_s
            end
            current = current.parent
          end

          # Default to current directory
          Dir.pwd
        end

        def default_search_paths
          [
            "dev-taskflow/current/*/tasks",
            "dev-taskflow/backlog"
          ]
        end

        def extract_task_number(identifier)
          return nil if identifier.nil?

          # Check if autocorrection is enabled
          autocorrect_enabled = @config.dig("autocorrect", "enabled") != false
          pad_zeros = @config.dig("autocorrect", "pad_zeros") != false

          # Handle different formats:
          # - "018", "18" -> "018"
          # - "v.0.9.0+task.018" -> "018"
          # - "task.018" -> "018"

          if identifier =~ /task\.(\d+)/
            number = $1
            autocorrect_enabled && pad_zeros ? number.rjust(3, "0") : number
          elsif identifier =~ /^(\d+)$/
            number = $1
            autocorrect_enabled && pad_zeros ? number.rjust(3, "0") : number
          else
            identifier # Return as-is and let the search handle it
          end
        end
      end
    end
  end
end