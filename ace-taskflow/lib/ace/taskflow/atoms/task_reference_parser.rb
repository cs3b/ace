# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure function to parse qualified task references (v.0.9.0+018, backlog+025)
      class TaskReferenceParser
        # Regular expression for qualified task references
        # Supports: v.0.9.0+018, v.0.9.0+task.018, backlog+025, backlog+task.025
        QUALIFIED_REFERENCE_PATTERN = /^([\w\.-]+)\+(?:task\.)?(\d+)$/

        # Regular expression for simple task references
        SIMPLE_REFERENCE_PATTERN = /^(?:task\.)?(\d+)$/

        # Regular expression for release version pattern
        RELEASE_VERSION_PATTERN = /^v\.\d+\.\d+\.\d+([-\w]+)?$/

        # Parse a task reference into its components
        # @param reference [String] The task reference to parse
        # @return [Hash, nil] Hash with :release and :number, or nil if invalid
        def self.parse(reference)
          return nil if reference.nil? || reference.empty?

          reference = reference.to_s.strip

          # Check for qualified reference (e.g., v.0.9.0+018, backlog+025)
          if match = reference.match(QUALIFIED_REFERENCE_PATTERN)
            release_str = match[1]
            number = match[2]

            return {
              release: normalize_release(release_str),
              number: number,
              qualified: true,
              original: reference
            }
          end

          # Check for simple reference (e.g., 018, task.018)
          if match = reference.match(SIMPLE_REFERENCE_PATTERN)
            return {
              release: "current",
              number: match[1],
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
        # @param qualified [Boolean] Whether to create qualified reference
        # @return [String] The formatted reference
        def self.format(release, number, qualified: true)
          number_str = number.to_s.rjust(3, '0')

          if qualified
            if release == "current"
              # Even for current, if explicitly qualified, include it without task. prefix
              "current+#{number_str}"
            elsif is_release_version?(release)
              # Release versions get the task. prefix
              "#{release}+task.#{number_str}"
            else
              # Other releases (like backlog) get the task. prefix
              "#{release}+task.#{number_str}"
            end
          else
            number_str
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
              format(release, parsed[:number], qualified: true)
            end
          when :simple
            parsed[:number].to_s.rjust(3, '0')
          else
            nil
          end
        end

        # Extract all task references from text
        # @param text [String] The text to search
        # @return [Array<String>] Array of found references
        def self.extract_references(text)
          return [] if text.nil? || text.empty?

          references = []

          # Find qualified references with task. prefix (e.g., v.0.9.0+task.018, backlog+task.025)
          text.scan(/\b([\w\.-]+)\+task\.(\d+)\b/) do |release_str, number|
            references << "#{release_str}+task.#{number}"
          end

          # Find qualified references without task. prefix (e.g., v.0.9.0+018, backlog+025)
          # Only capture if not already captured with task. prefix
          text.scan(/\b([\w\.-]+)\+(\d+)\b/) do |release_str, number|
            ref_with_task = "#{release_str}+task.#{number}"
            ref_without_task = "#{release_str}+#{number}"
            # Only add if the task. version wasn't already found
            references << ref_without_task unless references.include?(ref_with_task)
          end

          # Find simple task references (e.g., task.003)
          text.scan(/\btask\.(\d+)\b/) do |number|
            references << "task.#{number[0]}"
          end

          references.uniq
        end

        # Normalize a reference to canonical ID format
        # @param reference [String] The task reference to normalize
        # @param release_resolver [#resolve_release] Object that can resolve "current" to actual release
        # @return [String, nil] Canonical ID (e.g., "v.0.9.0+task.072") or nil if invalid
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

          # Build canonical ID: release+task.number
          # Ensure number is zero-padded to 3 digits
          padded_number = parsed[:number].to_s.rjust(3, '0')
          "#{release}+task.#{padded_number}"
        end
      end
    end
  end
end