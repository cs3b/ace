# frozen_string_literal: true

module Ace
  module Prompt
    module Atoms
      # Resolve task ID to prompt path within task directory
      class TaskPathResolver
        # Resolve task number to prompt directory path
        # @param task_id [String, Integer] Task number (e.g., 117, "117", "task.117")
        # @param taskflow_root [String] Root path for taskflow (default: .ace-taskflow)
        # @return [String, nil] Path to task prompts directory, or nil if not found
        def self.resolve(task_id, taskflow_root: ".ace-taskflow")
          normalized_id = normalize_task_id(task_id)
          return nil unless normalized_id

          # Find all task directories matching the ID pattern
          pattern = File.join(taskflow_root, "**", "*-*", "**", "*#{normalized_id}*")
          matches = Dir.glob(pattern).select { |path| File.directory?(path) }

          return nil if matches.empty?

          # Use the most recent (last modified) match
          latest_match = matches.max_by { |path| File.mtime(path) }
          File.join(latest_match, "prompts")
        end

        # Normalize task ID to standard format
        # @param task_id [String, Integer] Task identifier
        # @return [String, nil] Normalized task ID (e.g., "117")
        def self.normalize_task_id(task_id)
          return nil if task_id.nil?

          id_str = task_id.to_s.strip
          # Extract number from formats: "117", "task.117", "v.0.9.0+task.117"
          if id_str.match(/(\d+)/)
            $1
          else
            nil
          end
        end
      end
    end
  end
end
