# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module TaskflowManagement
      # TaskIdParser provides utilities for parsing and validating task IDs
      # This is an atom - it has no dependencies on other parts of this gem
      class TaskIdParser
        # Task ID format: v.X.Y.Z+task.N (e.g., v.0.3.0+task.05)
        TASK_ID_REGEX = /^(v\.\d+\.\d+\.\d+)\+task\.(\d+)$/
        VERSION_REGEX = /^v\.\d+\.\d+\.\d+$/
        SEQUENTIAL_NUMBER_REGEX = /\+task\.(\d+)/

        # Parse a task ID into its components
        # @param task_id [String] Task ID to parse (e.g., "v.0.3.0+task.05")
        # @return [Hash] Hash with :version and :sequential_number keys
        # @raise [ArgumentError] If task_id is invalid
        def self.parse(task_id)
          raise ArgumentError, "task_id must be a string" unless task_id.is_a?(String)
          raise ArgumentError, "task_id cannot be nil or empty" if task_id.nil? || task_id.empty?

          match = task_id.match(TASK_ID_REGEX)
          raise ArgumentError, "Invalid task ID format: #{task_id}. Expected format: v.X.Y.Z+task.N" unless match

          {
            version: match[1],
            sequential_number: match[2].to_i
          }
        end

        # Extract version from task ID
        # @param task_id [String] Task ID (e.g., "v.0.3.0+task.05")
        # @return [String] Version string (e.g., "v.0.3.0")
        def self.extract_version(task_id)
          parse(task_id)[:version]
        end

        # Extract sequential number from task ID
        # @param task_id [String] Task ID (e.g., "v.0.3.0+task.05")
        # @return [Integer] Sequential number (e.g., 5)
        def self.extract_sequential_number(task_id)
          parse(task_id)[:sequential_number]
        end

        # Validate task ID format
        # @param task_id [String] Task ID to validate
        # @return [Boolean] True if valid, false otherwise
        def self.valid?(task_id)
          return false unless task_id.is_a?(String)
          return false if task_id.nil? || task_id.empty?

          task_id.match?(TASK_ID_REGEX)
        end

        # Validate version format
        # @param version [String] Version string to validate (e.g., "v.0.3.0")
        # @return [Boolean] True if valid, false otherwise
        def self.valid_version?(version)
          return false unless version.is_a?(String)
          return false if version.nil? || version.empty?

          version.match?(VERSION_REGEX)
        end

        # Generate next task ID for a given version
        # @param version [String] Version string (e.g., "v.0.3.0")
        # @param current_max [Integer] Current maximum sequential number (default: 0)
        # @return [String] Next task ID with zero-padded sequential number
        # @raise [ArgumentError] If version is invalid
        def self.generate_next_id(version, current_max: 0)
          raise ArgumentError, "Invalid version format: #{version}" unless valid_version?(version)

          unless current_max.is_a?(Integer) && current_max >= 0
            raise ArgumentError,
              "current_max must be a non-negative integer"
          end

          next_number = current_max + 1
          formatted_number = next_number.to_s.rjust(2, "0")
          "#{version}+task.#{formatted_number}"
        end

        # Sort task IDs by version then sequential number
        # @param task_ids [Array<String>] Array of task IDs to sort
        # @return [Array<String>] Sorted array of task IDs
        def self.sort_task_ids(task_ids)
          return [] if task_ids.nil? || task_ids.empty?

          task_ids.sort do |a, b|
            parsed_a = parse(a)
            parsed_b = parse(b)

            # First compare by version
            version_comparison = compare_versions(parsed_a[:version], parsed_b[:version])
            if version_comparison != 0
              version_comparison
            else
              # Then compare by sequential number
              parsed_a[:sequential_number] <=> parsed_b[:sequential_number]
            end
          rescue ArgumentError
            # If parsing fails, use string comparison as fallback
            a <=> b
          end
        end

        # Compare two version strings
        # @param version_a [String] First version (e.g., "v.0.3.0")
        # @param version_b [String] Second version (e.g., "v.0.2.1")
        # @return [Integer] -1 if a < b, 0 if a == b, 1 if a > b
        def self.compare_versions(version_a, version_b)
          return 0 if version_a == version_b

          # Extract numeric parts
          parts_a = version_a.gsub(/^v\./, "").split(".").map(&:to_i)
          parts_b = version_b.gsub(/^v\./, "").split(".").map(&:to_i)

          # Compare each part
          [parts_a.length, parts_b.length].max.times do |i|
            part_a = parts_a[i] || 0
            part_b = parts_b[i] || 0

            comparison = part_a <=> part_b
            return comparison if comparison != 0
          end

          0
        end

        # Extract sequential number from any string containing task ID pattern
        # @param text [String] Text that may contain task ID (e.g., filename, content)
        # @return [Integer, nil] Sequential number if found, nil otherwise
        def self.extract_sequential_from_text(text)
          return nil unless text.is_a?(String)
          return nil if text.empty?

          match = text.match(SEQUENTIAL_NUMBER_REGEX)
          match ? match[1].to_i : nil
        end

        # Build task ID from components
        # @param version [String] Version string (e.g., "v.0.3.0")
        # @param sequential_number [Integer] Sequential number
        # @param zero_pad [Boolean] Whether to zero-pad the sequential number (default: true)
        # @return [String] Complete task ID
        # @raise [ArgumentError] If inputs are invalid
        def self.build_task_id(version, sequential_number, zero_pad: true)
          raise ArgumentError, "Invalid version format: #{version}" unless valid_version?(version)

          unless sequential_number.is_a?(Integer) && sequential_number > 0
            raise ArgumentError,
              "sequential_number must be a positive integer"
          end

          formatted_number = if zero_pad
            sequential_number.to_s.rjust(2, "0")
          else
            sequential_number.to_s
          end

          "#{version}+task.#{formatted_number}"
        end

        # Check if a task ID belongs to a specific version
        # @param task_id [String] Task ID to check
        # @param version [String] Version to match against
        # @return [Boolean] True if task ID belongs to version
        def self.belongs_to_version?(task_id, version)
          return false unless valid?(task_id) && valid_version?(version)

          extract_version(task_id) == version
        end
      end
    end
  end
end
