# frozen_string_literal: true

module Ace
  module Context
    module Atoms
      # Pure function to count lines in content
      # Follows ATOM architecture: no side effects, single purpose
      module LineCounter
        class << self
          # Count the number of lines in content
          # @param content [String, nil] Content to count lines in
          # @return [Integer] Number of lines (0 for empty/nil content)
          #
          # @example Empty content
          #   LineCounter.count("")  # => 0
          #
          # @example Single line
          #   LineCounter.count("hello")  # => 1
          #
          # @example Multiple lines
          #   LineCounter.count("a\nb\nc")  # => 3
          #
          # @example Trailing newline (does not add extra line)
          #   LineCounter.count("a\nb\n")  # => 2
          def count(content)
            return 0 if content.nil? || content.empty?

            # Count actual lines of content
            # "a\nb\nc" => 3 lines
            # "a\nb\n" => 2 lines (trailing newline doesn't add a line)
            content.count("\n") + (content.end_with?("\n") ? 0 : 1)
          end
        end
      end
    end
  end
end
