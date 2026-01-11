# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure function to parse qualified task references (v.0.9.0+018, backlog+025)
      # Supports hierarchical task IDs for subtasks (121, 121.00, 121.01, v.0.9.0+task.121.01)
      class TaskReferenceParser
        # Regular expression for qualified task references with subtasks
        # Supports: v.0.9.0+task.121.01, backlog+task.025.03
        HIERARCHICAL_QUALIFIED_PATTERN = /^([\w\.-]+)\+(?:task\.)?(\d+)\.(\d{2})$/

        # Regular expression for simple hierarchical task references
        # Supports: 121.01, task.121.00
        HIERARCHICAL_SIMPLE_PATTERN = /^(?:task\.)?(\d+)\.(\d{2})$/

        # Regular expression for qualified task references
        # Supports: v.0.9.0+018, v.0.9.0+task.018, backlog+025, backlog+task.025
        QUALIFIED_REFERENCE_PATTERN = /^([\w\.-]+)\+(?:task\.)?(\d+)$/

        # Regular expression for simple task references
        SIMPLE_REFERENCE_PATTERN = /^(?:task\.)?(\d+)$/

        # Regular expression for release version pattern
        RELEASE_VERSION_PATTERN = /^v\.\d+\.\d+\.\d+([-\w]+)?$/

        # Parse a task reference into its components
        # @param reference [String, Numeric] The task reference to parse (supports numeric for YAML-parsed subtask IDs)
        # @return [Hash, nil] Hash with :release, :number, :subtask, or nil if invalid
        def self.parse(reference)
          return nil if reference.nil?

          reference = reference.to_s.strip
          return nil if reference.empty?

          # Check for hierarchical qualified reference (e.g., v.0.9.0+task.121.01)
          # Must be checked before non-hierarchical patterns (more specific)
          if match = reference.match(HIERARCHICAL_QUALIFIED_PATTERN)
            release_str = match[1]
            number = match[2]
            subtask = match[3]

            return {
              release: normalize_release(release_str),
              number: number,
              subtask: subtask,
              qualified: true,
              original: reference
            }
          end

          # Check for hierarchical simple reference (e.g., 121.01, task.121.00)
          if match = reference.match(HIERARCHICAL_SIMPLE_PATTERN)
            return {
              release: "current",
              number: match[1],
              subtask: match[2],
              qualified: false,
              original: reference
            }
          end

          # Check for qualified reference (e.g., v.0.9.0+018, backlog+025)
          if match = reference.match(QUALIFIED_REFERENCE_PATTERN)
            release_str = match[1]
            number = match[2]

            return {
              release: normalize_release(release_str),
              number: number,
              subtask: nil,
              qualified: true,
              original: reference
            }
          end

          # Check for simple reference (e.g., 018, task.018)
          if match = reference.match(SIMPLE_REFERENCE_PATTERN)
            return {
              release: "current",
              number: match[1],
              subtask: nil,
              qualified: false,
              original: reference
            }
          end

          # Invalid reference
          nil
        end

        # Check if a reference is valid
        # @param reference [String] The reference to validate
        # @return [Boolean] True if valid, false otherwise
        def self.valid?(reference)
          !parse(reference).nil?
        end

        # Check if a reference is qualified
        # @param reference [String] The reference to check
        # @return [Boolean] True if qualified, false otherwise
        def self.qualified?(reference)
          result = parse(reference)
          result && result[:qualified]
        end

        # Check if a parsed result represents an orchestrator task (subtask .00)
        # @param parsed [Hash] The parsed result from parse()
        # @return [Boolean] True if orchestrator, false otherwise
        def self.is_orchestrator?(parsed)
          return false unless parsed.is_a?(Hash)

          parsed[:subtask] == "00"
        end

        # Check if a parsed result represents a subtask (subtask .01-.99)
        # @param parsed [Hash] The parsed result from parse()
        # @return [Boolean] True if subtask, false otherwise
        def self.is_subtask?(parsed)
          return false unless parsed.is_a?(Hash)

          !parsed[:subtask].nil? && parsed[:subtask] != "00"
        end

        # Check if a parsed result has any subtask notation (.00 or .01-.99)
        # @param parsed [Hash] The parsed result from parse()
        # @return [Boolean] True if hierarchical, false otherwise
        def self.is_hierarchical?(parsed)
          return false unless parsed.is_a?(Hash)

          !parsed[:subtask].nil?
        end

        # Get the parent task number from a parsed result
        # For subtasks, this is the main task number (e.g., "121" from "121.01")
        # @param parsed [Hash] The parsed result from parse()
        # @return [String, nil] The parent number, or nil if not hierarchical
        def self.parent_number(parsed)
          return nil unless parsed.is_a?(Hash)

          # For both orchestrators (.00) and subtasks (.01-.99), the parent is the main number
          parsed[:number]
        end

        # Normalize a release string
        # @param release [String] The release to normalize
        # @return [String] The normalized release
        def self.normalize_release(release)
          case release.downcase
          when "current", "active"
            "current"
          when "backlog"
            "backlog"
          else
            # Keep release versions as-is
            release
          end
        end

        # Check if a string is a release version
        # @param release [String] The string to check
        # @return [Boolean] True if it's a release version
        def self.is_release_version?(release)
          release.match?(RELEASE_VERSION_PATTERN)
        end

        # Format a task reference
        # @param release [String] The release
        # @param number [String, Integer] The task number
        # @param subtask [String, Integer, nil] Optional subtask number (e.g., "01", 1)
        # @param qualified [Boolean] Whether to create qualified reference
        # @return [String] The formatted reference
        def self.format(release, number, subtask: nil, qualified: true)
          number_str = number.to_s.rjust(3, '0')
          subtask_suffix = subtask.nil? ? "" : ".#{subtask.to_s.rjust(2, '0')}"

          if qualified
            if release == "current"
              # Even for current, if explicitly qualified, include it without task. prefix
              "current+#{number_str}#{subtask_suffix}"
            elsif is_release_version?(release)
              # Release versions get the task. prefix
              "#{release}+task.#{number_str}#{subtask_suffix}"
            else
              # Other releases (like backlog) get the task. prefix
              "#{release}+task.#{number_str}#{subtask_suffix}"
            end
          else
            "#{number_str}#{subtask_suffix}"
          end
        end

        # Convert between reference formats
        # @param reference [String] The reference to convert
        # @param target_format [Symbol] The target format (:qualified or :simple)
        # @param release [String] Optional release for simple->qualified conversion
        # @return [String, nil] The converted reference or nil if invalid
        def self.convert(reference, target_format, release: "current")
          parsed = parse(reference)
          return nil unless parsed

          case target_format
          when :qualified
            # If already qualified, return as is
            if parsed[:qualified]
              parsed[:original]
            else
              # Convert simple to qualified with provided release
              # Preserve subtask if present
              format(release, parsed[:number], subtask: parsed[:subtask], qualified: true)
            end
          when :simple
            # Build simple reference, preserving subtask suffix if present
            simple = parsed[:number].to_s.rjust(3, '0')
            parsed[:subtask] ? "#{simple}.#{parsed[:subtask]}" : simple
          else
            nil
          end
        end

        # Extract all task references from text using 6-pass scanning strategy
        #
        # Strategy Overview:
        # We scan from most specific to least specific patterns to avoid false positives
        # and prevent capturing the same reference in multiple formats. Each pass includes
        # exclusion logic to skip matches that were already found in more specific patterns.
        #
        # Why this order matters:
        # - Hierarchical patterns (with subtasks) must be scanned before simple patterns
        # - Qualified references (with releases) must be scanned before unqualified ones
        # - Negative lookbehind prevents partial matches within larger references
        #
        # @param text [String] The text to search
        # @return [Array<String>] Array of found references
        def self.extract_references(text)
          return [] if text.nil? || text.empty?

          references = []

          # 1. Qualified with task. prefix AND subtask (e.g., v.0.9.0+task.121.01)
          # Must be scanned first (more specific pattern)
          text.scan(/\b([\w\.-]+)\+task\.(\d+)\.(\d{2})\b/) do |release_str, number, subtask|
            references << "#{release_str}+task.#{number}.#{subtask}"
          end

          # 2. Qualified with task. prefix, NO subtask (e.g., v.0.9.0+task.018)
          text.scan(/\b([\w\.-]+)\+task\.(\d+)\b/) do |release_str, number|
            ref = "#{release_str}+task.#{number}"
            # Only add if hierarchical version wasn't already found
            references << ref unless references.any? { |r| r.start_with?(ref + ".") }
          end

          # 3. Qualified without task. prefix + subtask (e.g., v.0.9.0+121.01)
          text.scan(/\b([\w\.-]+)\+(\d+)\.(\d{2})\b/) do |release_str, number, subtask|
            ref = "#{release_str}+#{number}.#{subtask}"
            ref_with_task = "#{release_str}+task.#{number}.#{subtask}"
            references << ref unless references.include?(ref_with_task)
          end

          # 4. Qualified without task. prefix, NO subtask (e.g., v.0.9.0+018, backlog+025)
          text.scan(/\b([\w\.-]+)\+(\d+)\b/) do |release_str, number|
            ref_with_task = "#{release_str}+task.#{number}"
            ref_without_task = "#{release_str}+#{number}"
            # Only add if task. version or hierarchical version wasn't already found
            next if references.include?(ref_with_task)
            next if references.any? { |r| r.start_with?(ref_without_task + ".") }
            references << ref_without_task
          end

          # 5. Simple task references WITH subtask (e.g., task.121.01)
          # Use negative lookbehind to avoid matching within qualified references
          text.scan(/(?<!\+)task\.(\d+)\.(\d{2})\b/) do |number, subtask|
            ref = "task.#{number}.#{subtask}"
            # Skip if this is part of a qualified reference we already found
            next if references.any? { |r| r.end_with?(ref) }
            references << ref
          end

          # 6. Simple task references, NO subtask (e.g., task.003)
          # Use negative lookbehind to avoid matching within qualified references
          text.scan(/(?<!\+)task\.(\d+)\b/) do |number|
            ref = "task.#{number[0]}"
            # Only add if not already found and hierarchical version wasn't already found
            next if references.any? { |r| r.end_with?(ref) || r.end_with?(ref + ".") || r.start_with?(ref + ".") }
            references << ref unless references.any? { |r| r.start_with?(ref + ".") }
          end

          references.uniq
        end

        # Normalize a reference to canonical ID format
        # @param reference [String] The task reference to normalize
        # @param release_resolver [#resolve_release] Object that can resolve "current" to actual release
        # @return [String, nil] Canonical ID (e.g., "v.0.9.0+task.072" or "v.0.9.0+task.121.01") or nil if invalid
        def self.normalize_to_canonical_id(reference, release_resolver)
          parsed = parse(reference)
          return nil unless parsed

          # Resolve release to actual release name
          release = if parsed[:release] == "current"
            # Ask the resolver for the actual current release
            resolved = release_resolver.resolve_release(parsed[:release])
            resolved || parsed[:release]
          else
            parsed[:release]
          end

          # Build canonical ID: release+task.number[.subtask]
          # Ensure number is zero-padded to 3 digits
          padded_number = parsed[:number].to_s.rjust(3, '0')
          subtask_suffix = parsed[:subtask] ? ".#{parsed[:subtask]}" : ""
          "#{release}+task.#{padded_number}#{subtask_suffix}"
        end

        # Extract the task number from a full canonical task ID
        # @since 0.24.0
        # @param id [String] The task ID (e.g., "v.0.9.0+task.140.02" -> "140.02")
        # @return [String, nil] The task number (e.g., "140.02") or nil if invalid format
        def self.extract_number(id)
          return nil if id.nil?
          id_str = id.to_s
          # Extract task suffix - focuses on +task.NN or +task.NN.NN pattern
          # More flexible: doesn't enforce specific versioning scheme (semver, calver, etc.)
          return nil unless id_str.match?(/\+task\.\d+(?:\.\d+)?\z/)
          # Extract just the task number after +task. using non-greedy match
          id_str[/\+task\.(.+?)\z/, 1]
        end
      end
    end
  end
end