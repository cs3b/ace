# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for string normalization and formatting
      # Unit testable - no I/O
      class StringNormalizer
        # Normalize string for filesystem use
        # @param input [String] Input string
        # @return [String] Normalized string
        def self.normalize_for_filename(input)
          return "" if input.nil? || input.empty?

          input
            .downcase
            .gsub(/[^a-z0-9]+/, '-')
            .gsub(/^-|-$/, '')
            .gsub(/-+/, '-')
        end

        # Slugify string
        # @param input [String] Input string
        # @param separator [String] Separator character
        # @return [String] Slugified string
        def self.slugify(input, separator: '-')
          return "" if input.nil? || input.empty?

          input
            .downcase
            .gsub(/[^a-z0-9\s_-]/, '')
            .gsub(/[\s_-]+/, separator)
            .gsub(/^#{Regexp.escape(separator)}|#{Regexp.escape(separator)}$/, '')
        end

        # Titleize string
        # @param input [String] Input string
        # @return [String] Titleized string
        def self.titleize(input)
          return "" if input.nil? || input.empty?

          input
            .split(/[\s_-]+/)
            .map(&:capitalize)
            .join(' ')
        end

        # Truncate string with ellipsis
        # @param input [String] Input string
        # @param length [Integer] Max length
        # @param ellipsis [String] Ellipsis string
        # @return [String] Truncated string
        def self.truncate(input, length:, ellipsis: '...')
          return "" if input.nil?
          return input if input.length <= length

          truncated_length = length - ellipsis.length
          return ellipsis if truncated_length <= 0

          input[0...truncated_length] + ellipsis
        end

        # Extract initials from string
        # @param input [String] Input string
        # @param max_initials [Integer] Maximum number of initials
        # @return [String] Initials
        def self.extract_initials(input, max_initials: 3)
          return "" if input.nil? || input.empty?

          words = input.split(/[\s_-]+/).reject(&:empty?)
          initials = words.first(max_initials).map { |word| word[0].upcase }
          initials.join
        end

        # Normalize whitespace
        # @param input [String] Input string
        # @return [String] Normalized string
        def self.normalize_whitespace(input)
          return "" if input.nil?

          input
            .gsub(/\s+/, ' ')
            .strip
        end

        # Remove special characters
        # @param input [String] Input string
        # @param keep [String] Characters to keep
        # @return [String] Cleaned string
        def self.remove_special_chars(input, keep: '')
          return "" if input.nil?

          pattern = /[^a-zA-Z0-9\s#{Regexp.escape(keep)}]/
          input.gsub(pattern, '')
        end

        # Convert to snake_case
        # @param input [String] Input string
        # @return [String] Snake-cased string
        def self.to_snake_case(input)
          return "" if input.nil? || input.empty?

          input
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .gsub(/[\s-]+/, '_')
            .downcase
        end

        # Convert to camelCase
        # @param input [String] Input string
        # @param first_upper [Boolean] Uppercase first letter (PascalCase)
        # @return [String] Camel-cased string
        def self.to_camel_case(input, first_upper: false)
          return "" if input.nil? || input.empty?

          words = input.split(/[\s_-]+/).reject(&:empty?)
          return "" if words.empty?

          result = words.map.with_index do |word, index|
            if index == 0 && !first_upper
              word.downcase
            else
              word.capitalize
            end
          end.join

          result
        end

        # Wrap text to specified width
        # @param input [String] Input text
        # @param width [Integer] Max line width
        # @return [String] Wrapped text
        def self.wrap_text(input, width:)
          return "" if input.nil? || width <= 0

          words = input.split(/\s+/)
          lines = []
          current_line = []

          words.each do |word|
            test_line = (current_line + [word]).join(' ')
            if test_line.length <= width
              current_line << word
            else
              lines << current_line.join(' ') unless current_line.empty?
              current_line = [word]
            end
          end

          lines << current_line.join(' ') unless current_line.empty?
          lines.join("\n")
        end
      end
    end
  end
end
