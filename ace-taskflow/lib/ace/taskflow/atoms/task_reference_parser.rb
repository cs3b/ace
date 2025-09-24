# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure function to parse qualified task references (v.0.9.0+018, backlog+025)
      class TaskReferenceParser
        # Regular expression for qualified task references
        QUALIFIED_REFERENCE_PATTERN = /^([\w\.-]+)\+(\d+)$/

        # Regular expression for simple task references
        SIMPLE_REFERENCE_PATTERN = /^(?:task\.)?(\d+)$/

        # Regular expression for release version pattern
        RELEASE_VERSION_PATTERN = /^v\.\d+\.\d+\.\d+([-\w]+)?$/

        # Parse a task reference into its components
        # @param reference [String] The task reference to parse
        # @return [Hash, nil] Hash with :context and :number, or nil if invalid
        def self.parse(reference)
          return nil if reference.nil? || reference.empty?

          reference = reference.to_s.strip

          # Check for qualified reference (e.g., v.0.9.0+018, backlog+025)
          if match = reference.match(QUALIFIED_REFERENCE_PATTERN)
            context = match[1]
            number = match[2]

            return {
              context: normalize_context(context),
              number: number,
              qualified: true,
              original: reference
            }
          end

          # Check for simple reference (e.g., 018, task.018)
          if match = reference.match(SIMPLE_REFERENCE_PATTERN)
            return {
              context: "current",
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

        # Normalize a context string
        # @param context [String] The context to normalize
        # @return [String] The normalized context
        def self.normalize_context(context)
          case context.downcase
          when "current", "active"
            "current"
          when "backlog"
            "backlog"
          else
            # Keep release versions as-is
            context
          end
        end

        # Check if a context is a release version
        # @param context [String] The context to check
        # @return [Boolean] True if it's a release version
        def self.release_context?(context)
          context.match?(RELEASE_VERSION_PATTERN)
        end

        # Format a task reference
        # @param context [String] The context
        # @param number [String, Integer] The task number
        # @param qualified [Boolean] Whether to create qualified reference
        # @return [String] The formatted reference
        def self.format(context, number, qualified: true)
          number_str = number.to_s.rjust(3, '0')

          if qualified
            if context == "current"
              # Even for current, if explicitly qualified, include it
              "current+#{number_str}"
            else
              "#{context}+#{number_str}"
            end
          else
            number_str
          end
        end

        # Convert between reference formats
        # @param reference [String] The reference to convert
        # @param target_format [Symbol] The target format (:qualified or :simple)
        # @param context [String] Optional context for simple->qualified conversion
        # @return [String, nil] The converted reference or nil if invalid
        def self.convert(reference, target_format, context: "current")
          parsed = parse(reference)
          return nil unless parsed

          case target_format
          when :qualified
            # If already qualified, return as is
            if parsed[:qualified]
              parsed[:original]
            else
              # Convert simple to qualified with provided context
              format(context, parsed[:number], qualified: true)
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

          # Find qualified references (e.g., v.0.9.0+018, backlog+025)
          text.scan(/\b([\w\.-]+)\+(\d+)\b/) do |context, number|
            references << "#{context}+#{number}"
          end

          # Find simple task references (e.g., task.003)
          text.scan(/\btask\.(\d+)\b/) do |number|
            references << "task.#{number[0]}"
          end

          references.uniq
        end
      end
    end
  end
end