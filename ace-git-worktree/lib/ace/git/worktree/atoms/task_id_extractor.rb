# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Extracts task IDs from task data, preserving hierarchical subtask notation
        #
        # This atom provides a single source of truth for task ID extraction across
        # ace-git-worktree, ensuring consistent handling of hierarchical task IDs
        # (e.g., "121.01" for subtasks).
        #
        # @example Extract from task data hash
        #   TaskIDExtractor.extract({id: "v.0.9.0+task.121.01"}) # => "121.01"
        #   TaskIDExtractor.extract({id: "v.0.9.0+task.121"})    # => "121"
        #
        # @example Normalize a task reference string
        #   TaskIDExtractor.normalize("v.0.9.0+task.121.01") # => "121.01"
        #   TaskIDExtractor.normalize("task.121")            # => "121"
        #   TaskIDExtractor.normalize("121.01")              # => "121.01"
        class TaskIDExtractor
          # Extract task ID from task data hash
          #
          # @param task_data [Hash] Task data with :id and/or :task_number
          # @return [String] Task ID (e.g., "121" or "121.01")
          def self.extract(task_data)
            return "unknown" unless task_data

            # Regex with subtask support
            if task_data[:id]
              # B36TS full ID: "8pp.t.hy4" -> "hy4", or subtask "8pp.t.hy4.a" -> "hy4.a"
              if match = task_data[:id].match(/\A[0-9a-z]{3}\.[a-z]\.([0-9a-z]{3}(?:\.[a-z0-9])?)\z/)
                return match[1]
              end
              # Try subtask pattern first (e.g., "v.0.9.0+task.121.01" -> "121.01")
              if match = task_data[:id].match(/task\.(\d+)\.(\d{2})$/)
                return "#{match[1]}.#{match[2]}"
              end
              # Then simple pattern (e.g., "v.0.9.0+task.094" -> "094")
              if match = task_data[:id].match(/task\.(\d+)$/)
                return match[1]
              end
              # Fallback for partial patterns (e.g., "task.121.1" -> "121", ignoring invalid suffix)
              if match = task_data[:id].match(/task\.(\d+)/)
                return match[1]
              end
            end

            # Last resort: use task_number (doesn't include subtask suffix)
            task_data[:task_number]&.to_s || "unknown"
          end

          # Normalize a task reference string to simple ID format
          #
          # @param task_ref [String] Task reference (e.g., "121.01", "v.0.9.0+task.121.01")
          # @return [String, nil] Normalized ID or nil if invalid
          def self.normalize(task_ref)
            ref = task_ref.to_s.strip
            return nil if ref.empty?

            # Regex patterns for recognized ACE task ID formats
            # B36TS full ID: "8pp.t.hy4" -> "hy4", or subtask "8pp.t.hy4.a" -> "hy4.a"
            if match = ref.match(/\A[0-9a-z]{3}\.[a-z]\.([0-9a-z]{3}(?:\.[a-z0-9])?)\z/)
              match[1]
            # B36TS short ref: exactly 3 lowercase alphanumeric chars (e.g., "hy4")
            elsif match = ref.match(/\A([0-9a-z]{3})\z/)
              match[1]
            # ACE task IDs are 3-digit zero-padded (081, 121, etc.)
            # Try hierarchical pattern first (e.g., "121.01", "task.121.01")
            elsif match = ref.match(/(\d{3})\.(\d{2})(?:\b|$)/)
              "#{match[1]}.#{match[2]}"
            # Try task. prefix pattern (e.g., "task.121")
            # Use negative lookbehind to avoid matching "ace-task.NNN" in directory names
            elsif match = ref.match(/(?<!ace-)task\.(\d{3})(?:\b|$)/)
              match[1]
            # Try bare 3-digit task ID (e.g., "121", "081")
            elsif match = ref.match(/\b(\d{3})\b/)
              match[1]
            end
          end
        end
      end
    end
  end
end
