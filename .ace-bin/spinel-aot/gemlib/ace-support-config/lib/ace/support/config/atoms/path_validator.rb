# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Atoms
        # Validates path segments for security
        # Prevents path traversal attacks via ".." and absolute paths (Unix and Windows)
        #
        # This module provides pure validation functions that check path segments
        # for potentially dangerous patterns without any side effects.
        #
        # @example Validate a namespace segment
        #   PathValidator.validate_segment!("valid_name")  # => true
        #   PathValidator.validate_segment!("..")          # => raises ArgumentError
        #   PathValidator.validate_segment!("/absolute")   # => raises ArgumentError
        #   PathValidator.validate_segment!("C:\\path")    # => raises ArgumentError
        #
        # @example Validate multiple segments
        #   PathValidator.validate_segments!(["config", "nested", "file"])  # => true
        #   PathValidator.validate_segments!(["config", "..", "secret"])    # => raises ArgumentError
        #
        module PathValidator
          class << self
            # Validate a single path segment for security
            # @param segment [String] Segment to validate
            # @raise [ArgumentError] If segment contains invalid characters
            # @return [true] If validation passes
            def validate_segment!(segment)
              if segment.include?("..")
                raise ArgumentError, "Invalid path segment: #{segment.inspect} (path traversal not allowed)"
              end
              if segment.start_with?("/")
                raise ArgumentError, "Invalid path segment: #{segment.inspect} (absolute paths not allowed)"
              end
              # Windows-style absolute paths: drive letters (C:) or UNC paths (\\server)
              if segment.start_with?("\\") || segment.match?(/\A[A-Za-z]:/)
                raise ArgumentError, "Invalid path segment: #{segment.inspect} (absolute paths not allowed)"
              end
              true
            end

            # Validate multiple path segments for security
            # @param segments [Array<String>] Segments to validate
            # @raise [ArgumentError] If any segment contains invalid characters
            # @return [true] If validation passes
            def validate_segments!(segments)
              segments.each { |segment| validate_segment!(segment) }
              true
            end

            # Check if a segment is valid (non-raising version)
            # @param segment [String] Segment to check
            # @return [Boolean] true if valid, false otherwise
            def valid_segment?(segment)
              validate_segment!(segment)
              true
            rescue ArgumentError
              false
            end

            # Check if all segments are valid (non-raising version)
            # @param segments [Array<String>] Segments to check
            # @return [Boolean] true if all valid, false otherwise
            def valid_segments?(segments)
              validate_segments!(segments)
              true
            rescue ArgumentError
              false
            end
          end
        end
      end
    end
  end
end
